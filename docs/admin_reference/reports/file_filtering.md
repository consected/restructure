# File Filtering

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
