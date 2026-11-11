# File Filtering

This page covers the `select items: download files` variant of report checkboxes, which lets users
download multiple files in one action.

For the `add to list` / `update list` / `remove from list` checkbox variants used by list-building
workflows (bulk messaging, variable selection, etc.) see
[Select Items: Checkbox Actions in Reports](select_items_lists.md).

---

Thew following is an example SQL query for viewing or downloading masses of documents within a regular tabular report.

Notice the use of `:file_filtering_conditions_for_activity_log__ipa_assignment_session_filestore`, which is substituted with inner join
SQL that limits the files the current user can see in the final report.

    select 
    al.master_id,
    ipa.ipa_id,
    al.extra_log_type "session type",
    al.select_status,
    filestore_report_file_path(nfs_store_stored_files::nfs_store_stored_files, nfs_store_archived_files::nfs_store_archived_files) "file path", 
    filestore_report_perform_action(c.id, 'activity_log__ipa_assignment_session_filestore', al.id, nfs_store_stored_files::nfs_store_stored_files,     
      nfs_store_archived_files::nfs_store_archived_files) "perform action: view file",
    filestore_report_select_fields(c.id, 'activity_log__ipa_assignment_session_filestore', al.id, nfs_store_stored_files.id, nfs_store_archived_files.id) "select items: download files"

    from activity_log_ipa_assignment_session_filestores al

    inner join ipa_assignments ipa
      on al.master_id = ipa.master_id

    inner join model_references mr
      on mr.from_record_type = 'ActivityLog::IpaAssignmentSessionFilestore'
        and al.master_id = mr.from_record_master_id
        and al.id = mr.from_record_id

    inner join nfs_store_containers c
      on mr.to_record_type = 'NfsStore::Manage::Container'
        and c.master_id = mr.to_record_master_id
        and c.id = mr.to_record_id

    inner join nfs_store_stored_files
      on c.id = nfs_store_stored_files.nfs_store_container_id

    left join nfs_store_archived_files
      on nfs_store_stored_files.id = nfs_store_archived_files.nfs_store_stored_file_id

    where ipa.ipa_id in (:ipa_ids) AND al.select_status IN ('open', 'closed')


    AND :file_filtering_conditions_for_activity_log__ipa_assignment_session_filestore

    order by 
      ipa_id, "session type", "file path", "perform action: view file"  
    ;

---

## How selected files are submitted

The `filestore_report_select_fields()` function returns a checkbox definition with the `field_name`
`nfs_store_download[selected_items][]`, whose value is a JSON object identifying the file
(`id`, `retrieval_type`, `container_id`, `activity_log_type`, `activity_log_id`).

When the user clicks **download files**, the checked values are not posted as individual form
parameters. Instead they are collected into a single parameter, `nfs_store_download[selected_items_json]`,
containing a JSON array of those objects, and posted to `/nfs_store/downloads/multi`. This avoids
the web server's limit of 4096 form parameters per request, so thousands of files can be selected
at once. The same single-parameter approach is used by the container file browser for download,
trash, move, rename and file-action requests to `/nfs_store/downloads`.

API clients may use either form. The legacy `nfs_store_download[selected_items][]` array of JSON
strings is still accepted, but should be avoided for large selections since it is subject to the
parameter limit. For example:

    nfs_store_download[selected_items_json]=[{"id":123,"retrieval_type":"stored_file"},{"id":45,"retrieval_type":"archived_file"}]

The overall request body remains subject to a 4 MB size limit.
