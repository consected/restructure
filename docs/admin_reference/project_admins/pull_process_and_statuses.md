# REDCap: Pull Process and Statuses

## Overview

When transferring records from a REDCap server to the local database, the process runs asynchronously in a background job. As the pull advances through each stage of retrieval, validation, and storage, the project's **record retrieval status** (shown in the **Details** panel) and the log in the **Requests** tab are continuously updated to reflect progress.

## Pull Progression Stages

A typical record pull follows this progression:

```
1. records request job set up
   ↓
2. retrieving records
   ↓
3. validating records
   ↓
4. checking for deleted records   (conditional)
   ↓
5. storing records
   ↓
6. manual run successful          (or completion with errors / failure)
```

### Detailed Stage Breakdown

| Stage | Status Displayed | Description |
| :--- | :--- | :--- |
| **0. Initial Queueing** | `records request job set up` | An administrator clicks **retrieve records** or an automated trigger starts a pull. Manual and API requests enqueue `Redcap::CaptureRecordsJob` and add a `setup job: store records` row in **Requests**. Scheduled pulls set the same status when `RecurringPullTask` begins, but do not create that setup row. |
| **1. API Retrieval** | `retrieving records` | The background worker picks up the job and connects to the remote REDCap API endpoint. If incremental mode (`export_only_updated_records`) is active, only records updated since `dateRangeBegin` are queried. |
| **2. Field Summary & Validation** | `validating records` | If multi-choice summary fields are enabled, checkbox fields are aggregated into array fields. The incoming record schema is checked against both the REDCap data dictionary and the destination dynamic model table to prevent saving mismatched or corrupt data. |
| **3. Deleted Records Check** | `checking for deleted records` | *Conditional:* When `handle_deleted_records` is set to `disable` and date filtering is not bypassing the check, local records not present in the REDCap export are flagged as disabled. |
| **4. Database Storage & File Imports** | `storing records` | Records are upserted into the target dynamic model in batches (default batch size: 100). Model callbacks and save triggers are executed for each record. File fields are downloaded and securely stored in the project's NFS filestore container. |
| **5. Completion** | `manual run successful`<br>*(or `scheduled run successful`)* | For a fresh pull, all retrieved records and associated files were successfully stored with zero errors. The final status confirms that storage stage `store complete` has been reached. A cache hit retains `records unchanged since last successful pull` instead. |

---

## Alternative and Terminal Statuses

Depending on the outcome of the pull, the final status will be set to one of the following:

### Successful with Per-Record Errors
- **Status:** `manual run completed with errors` *(or `scheduled run completed with errors`)*
- **Meaning:** The overall pull completed without an unhandled crash, but one or more individual records failed validation or callback execution (e.g. invalid format or constraint violation).
- **Inspection:** Check the `store records` entry in the **Requests** tab for the list of failed record IDs and specific error messages.

### Failure / Crash
- **Status:** `manual run failed` *(or `scheduled run failed` / `request failed`)*
- **Meaning:** An unexpected exception occurred during the process (e.g. database schema mismatch, missing required attribute, or network failure).
- **Inspection:** The **Details** panel shows a summary of the error, and a `capture records job` error entry with a backtrace appears in the **Requests** tab.

### Unchanged Records (Cache Hit)
- **Status:** `records unchanged since last successful pull`
- **Meaning:** The pull was requested within the cache window (default 60 seconds) following a recent successful pull. Because the records were already retrieved and processed, the validate and store steps were skipped to optimize performance, and this status remains visible as the outcome of the pull.

### Configuration Issues
- **Status:** `changes detected`
- **Meaning:** The destination dynamic model table is missing fields defined in the REDCap data dictionary. Records cannot be pulled until the dynamic model is updated. Click **update dynamic model** to synchronize fields.
- **Status:** `stopped manually`
- **Meaning:** The scheduled pull was disabled or stopped by an administrator.

---

## Caching and Error Recovery

To prevent overloading the remote REDCap API, successful record export responses are cached for a configurable duration (`record_export_cache_time`, default 60 seconds).

- **Cache Invalidation on Failure:** If validation or database storage fails with an exception, the system **automatically purges the records cache entry**.
- **Safe Retries:** Because the cache is invalidated upon failure, any subsequent retry (whether manual or automated) will make a fresh API call and re-run all validation and storage steps rather than falsely reporting success from stale cache.

---

## Monitoring Progress in the Admin Interface

1. **Details Tab:**
   - **record retrieval status:** Shows the current or final status described above.
   - **latest request:** Displays the timestamp of the most recent request and any immediate error message.
2. **Requests Tab:**
   - Displays a chronological audit table of every action taken (`setup job: store records`, `store records`, `records`, `project_xml`, etc.).
   - Expand the `store records` request result to view detailed metrics:
     - `count_retrieved`: Total records returned by REDCap.
     - `count_created_ids`: New records added to the local database.
     - `count_updated_ids`: Existing records updated.
     - `count_unchanged_ids`: Records whose values matched existing data.
     - `count_disabled_ids`: Records disabled due to deletion in REDCap.
     - `imported_files_count` / `failed_files_count` / `skipped_files_count`: File field download statistics.
     - `errors`: Specific record-level validation or saving errors.
3. **Updating the View:**
   - Because background workers update records asynchronously, click the **refresh** button at the top of the **Details** panel to view the latest status as processing advances.
