
# Core requirements

Decisions are made based on [mind map](notes_assets/TaskProcessingPipeline.png) created from task requirements.

## Task data model

Schema-related decisions:
- Using UUIDv7 as an `id` field. It includes timestamp at the beginning, so you can sort by `id` and get meaningful results.
- Model `priority` field as integer-based enum. It allows meaningful sorting, as well, and can be used for `priority` in Oban jobs. Remaining enums are string-based
- Added `version` field for optimistic locking to ensure proper concurrency. In case of race conditions, only one process will be able to update a record. Other will get an error. This way, we can control concurrency for changes without explicit locks (this is faster).

Index decisions:
- Primary key index was created by default.
- Index `["priority ASC", "id DESC", :type, :status]` covers many cases for `GET /api/tasks` endpoint. It allows to filter by `priority`, `priority and type`, `priority and type and status`. Also it supports ordering by priority (critical first) and creation time (newest first). As `id` field (UUIDv7) has a timestamp - it can be efficiently used to represent creation time, as well as to filter older items for cursor - based pagination. Of course, the timestamp in `id` may differ from the one in `created_at` field, and thus result in wrong order of some tasks (according to `created_at` field) - this is a conscious trade-off which allows to reduce resource usage.

![1](notes_assets/tasks_priority_ASC_id_DESC_type_status_index__1.png)

![2](notes_assets/tasks_priority_ASC_id_DESC_type_status_index__2.png)

![3](notes_assets/tasks_priority_ASC_id_DESC_type_status_index__3.png)

- Index `[:status, "priority ASC", "id DESC"]` cover filter by `status` or `priority and status` cases for `GET /api/tasks` endpoint. It also supports correct sorting by priority and creation time, but uses the same tradeoff, as a previous index. Also this index fully supports `GET /api/tasks/summary` endpoint and allows index-only scan for counting metrics. This allows to get results faster, and to, some extent to reduce a need in caching.

![4](notes_assets/tasks_status_priority_ASC_id_DESC_index__1.png)

![5](notes_assets/tasks_status_priority_ASC_id_DESC_index__2.png)

## Attempt tracking

Considered these approaches:
- Use separate table.
	- pros:
		- can compute statistics, using indexes
		- Can move this table to other storage, if needed
		- Can emit events when task status changes
	 - cons:
		 - Need to create separate table and store more data
 - Add embedded array to task
	 - pros:
		 - Easier to fetch together with task record
		 - No need to create another table
	 - cons:
		 - More difficult if we want to process analytics
 - Expand Oban:
	- pros:
		- Can reuse existing table, no need to create new one
	- cons:
		- If we want to prune processed jobs, then we will lose metrics.

Selected "separate table" approach:
- Created new table "task_progress"
- store there these fields:
	- id - UUIDv7 - can be used for ordering
	- task_id - reference a task
	- node_id - Identifier of the node, where the status was changed. This will help restoring "in-flight" tasks that were stuck.
	- start_time - the time, when task moved into this status
	- end_time - when task moved out of the status. By default is null
	- status - current status
	- metadata - additional information (for example, can store stack traces or other information about the failure)
- indexes:
	- id - primary key (default)
	- search status logs for a specific task `[:task_id, :status, :id, :end_time]`
	- `:node_id` - to search statuses, that were created by specific node
- This table can be used to compute metrics, for example, average time, when task is in specific status.
- If Elixir node dies, while the worker processes a task, the entry in this table will have `start_time` set, the status will be `processing`, but `end_time` will remain null. We can use node table information to track when the node was active, and search for all its unprocessed jobs. Then we can move them to correct state.
- When task status changes, I broadcast 2 PubSub events. The first one shows information about status changes in all tasks, the second one - for a change of a task with specific id. Changes in status of all tasks can be used for collecting metrics (for example, number of tasks in specific status). Second one can be used to get real-time information about the specific task (for example, pushing live updates via WebSocket).

## Node

Once started, each node records information about itself in the `nodes` table.
It also should periodically update its `last_active` field via Oban Cron job.

Each started Elixir node lazily creates the record in this table. This happens, when any function tries to get a `node_id` - this usually happens, when either a new task created, or existing one moves to new status.

The current node id uses singleton pattern (its Elixirish example) and double-checked locking via GenServer call. When the node was created, its value is cached in `:persistent_term` - this is more efficient than ETS tables, so it is shared inside the Beam VM.

This approach uses `LazyPersistentConfigBehaviour`. This behaviour can be used to create similar configs. For example, we can store node startup time, or some global value.

Tests use new node id for each call (instead of persisted one). This can be further improved by storing own node_id for each test in their process dictionary.


# REST API

## POST /api/tasks
- Quite straightforward, uses mostly code from generator
- Adopted to results of `Multi`

## GET /api/tasks
- Uses own changeset to validate parameters. For example, each query can use `per_page` parameter to limit number of items.
- It can either to use filters (search by status, type, priority) or cursor. Cursor already stores information about the filters, so it could be ambiguous if extra fields are present.
- `per_page` parameter works both for filters and cursor - it can be useful to change number of items per query.

## GET /api/tasks/:id
- Uses the code from `phx.gen.json`
- Potential improvement - show full information about task statuses. Now it returns only a brief information about the task.

## GET /api/tasks/summary
- uses index-only query for collecting metrics. This should scale well, but it is better to measure results under a real-world workloads. Can be cached, for example via ETS. This kind of caching will return stale data. Also this caching can lead to different responses, if API is deployed behind load-balancer. ETS is related to current node only, so the cached response will differ on different nodes.

## GET /api/tasks/metrics

This is not implemented, but can use PubSub to collect node-related metrics. Also can return data with Node id, and how many items are processed by current workers.

If we need to get global metrics - we can use "task_progress" table for it.

# Oban
- Oban was added to the project, but has not much configuration now - focused on database structure, REST API implementation and proper indexing.
- Picked "queue per task type" approach. Usually similar tasks use similar amount of resources, so it is better to group them together.
- Each queue will have jobs with different priorities. `priority` field in task schema can be mapped to integer value. It can be used directly to set a priority of the job.
- Periodic job (`Oban.Plugins.Cron`) can refresh alive status of each node.
- Periodic job can fix stuck "in-flight" jobs - it can search when the task is in "processing" status (it has no `end_time` int `task_progress` table), but there is no such alive node (`last_active` timestamp was changed too long ago). This job can restart these jobs.
- Periodic job can be used to temporary "increase" priority for jobs that were waiting for too long in the queue (fix "starvation" condition). For example, if the system is heavy under load with high priority tasks, the task with low priority may not get the processing time. This job can search for such jobs and increase their priority in Oban-related table. This way each task will be eventually processed. If this task gets an error while processing, its priority will be set back after moving it to "queued" state.
- Similar logic for each task type can be extracted to a single module. This module can define its own behaviour and allow to hook into certain parts of generic workflow.


# Code at scale
- Under load, potentially the task creation process may be a bottleneck, namely the database part. So it can be made async - the tasks could be stored in Kafka, and then integrated via Broadway, or similar solution. The endpoint can return the ID of the task (which can be generated as UUIDv7), and this task will become eventually available.
- `GET /api/tasks/summary` potentially may be cached via ETS, but it is better to measure first. It can be easier just to use database read-replica instead.
- We definitely will need more indexing for `task_progress` table to collect metrics. These metrics can be cached.
- Separate database read replica can be useful for `GET /api/tasks` endpoint. Right now it is already optimized (indices support different query configurations), but it is better to measure on real-world data.
- I would add behaviour for workers. I already have `LazyPersistentConfigBehaviour`, that allows to create configuration that rarely changes.
- I have a test `change_status/2 concurrent status modification raises an error` that checks concurrent modification of a task. If multiple processes will try to modify the task, only the first will succeed, the other one will fail. This is done via `optimistic_lock` in the changeset and specific field in the database.
- Error handling patterns. Now I propagate error from database transaction to the controller. It allows to present more information about errors to the user. All user-submitted data (task information and filter parameters for listing tasks) are checked via changesets in an uniform way.


# OTP architecture
- Metrics processing is not implemented. I would create each metric as GenServer and use Supervisor to track if they are alive. Since all metrics are not related to each other, I would pick `:one_for_one` strategy. If I needed to combine multiple metrics, I would broadcast relevant metrics via PubSub, and collect them together. Restart strategy would remain the same.
- ETS for caching is already discussed. I would cache only Node-related data by default (for example Node metrics). If different summary is OK, or if index-only search for summary would take too much time, then I would cache this data too. I would use (and already use) `:persistent_term` lazily initialize and cache Node-related data that does not change frequently (the id of the node).
- Supervision tree choices. Right now I have added own process related to node configuration to the root level.
- Fault tolerance. Now `LazyPersistentConfigBehaviour` is fault-tolerant. Even if process crashes, its value will be kept in `:persistent_term` storage, so it should work fine.


# System design
- The database uses multiple composite indexes that cover the most heavily-used queries. Have attached execution plans at the top of the document.
- The application has basic support for PubSub. It already stores each task status change as a separate record. Each of these records can be ordered by `id` field (UUIDv7), so this this table can also be used for event broadcasting.
- Potential bottlenecks at 10k tasks/min are heavy PubSub usage (especially if many tasks change). I already send tiny amount of data, so it should work well, but receiving end (GenServers that collect metrics) could be overloaded with messages, and that could eventually lead to failure of the whole node. In this case I would push metrics to different topics, so each GenServer would subscribe only to the relevant information. Another potential bottleneck is getting metrics from `task_progress` table. Right now it does not have index for calculating metrics - it should be created according to the requirements. For example, there could be an index that computes time in each status (`start_time` - `end_time`).
- Oban configuration depth. Right now only a single worker can change status of a task. Concurrent modification will fail due to optimistic lock. It would be fine to prune all processed jobs (or failed ones), because I already store all relevant information in another table. I plan to combine queue-per-type approach  with single-queue-for-priority approaches. This allows to group similar tasks together, while managing their priority. This can be scaled via generic worker and behaviours for specific parts of the algorithm.

# Potential next steps

- Remaining items can be distributed between team members, namely:
	- Cover corner cases for API with tests
	- return more data in response for `GET /api/tasks/:id` - full version together with status history
	- cover workers with tests
	- Implement Job processing
- If I had more time, I would configure Oban properly and implement task processing according to the requirements. The next step would be improving test coverage and comparing data against the requirements.
- I would test failed nodes with in-flight jobs, changing Oban jobs priority to fight with "starvation" and failed conditions. Also I would test if collected metrics are proper ones.
- I traded the Oban configuration for implementing API. Also I decided to use  separate table for task progress instead of using existing ones (either Oban jobs or embedded field in task). This allows to collect more metrics, and also use table as a stream of changes. Another tradeoff was using UUIDv7 vs UUIDv4, here I traded a part of uniqueness for ability to sort by id and reduce index space usage (no need to have a separate index for `created_at` column).
