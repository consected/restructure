# API scripts - samples and usage

This repo contains scripts to perform common actions using the API.

## Prerequisites

The following prerequisites must be available for these scripts to run:

- curl
- awk
- md5sum

## Uploading a directory of files to containers based on an ID

The script `upload-to-external-id-container` runs through all the files in a specified directory, using the filename on each file to look up the container to upload to. The file may be renamed with a suffix prior to uploading. The upload is then performed.

On the first script run, sub-directories will be created within the upload directory for files in specific statuses:

- failed
- in-progress
- success

For example, to upload to MRI containers on *Study Filestore app*, using filenames formatted like `<study-id>.tar.gz` to identify the participant to upload to.
Each file will have the suffix "_diffusion" added prior to upload, so they appear as `<study-id>_diffusion.tar.gz`

```bash
# The user credentials
export upload_user_email='<api username>'
export upload_user_token='<private token>'
# The directory to upload from
upload_dir='<absolute path to directory>'

# The server to upload to
export upload_server="https://<server domain name>"
# Add _diffusion to the filename before uploading
export fn_suffix='_diffusion'
# Sets the IPA app
export upload_app_type=7
# Sets up the container types to load to
export activity_log_type='activity_log__study_assignment_session_filestore'
export container_name='mri'
# File types to upload
export file_ext='.tar.gz'
# External ID attribute to find containers on
export external_id_attribute='study_id'
# Resource name for the report used to match IDs to containers
export report_name='study_files_api__study_find_container'

# Optionally set curl command additional arguments and flags
# This defaults to '-s' for silent requests
# export curl_args='-s -v'

# Now run the script
./upload-to-external-id-container.sh ${upload_dir}
```

The report used to look up containers is defined as:

Name: **Study Find Container**
Category: **study-files-api**
Report type: **regular_report**

SQL:

```sql
select 
  mr.to_record_id "container_id",
  al.id "activity_log_id",
  al.master_id,
  'activity_log__study_assignment_session_filestore' "activity_log_type"
from activity_log_study_assignment_session_filestores al
inner join study_assignments study 
  on 
    al.master_id = study.master_id
inner join model_references mr
  on 
    from_record_type = 'ActivityLog::IpaAssignmentSessionFilestore'
    and from_record_id = al.id
    and from_record_master_id = al.master_id
    and to_record_type = 'NfsStore::Manage::Container'
    and to_record_master_id = al.master_id
where 
  study_id = :study_id
  and extra_log_type = :session_type
  and al.select_status = 'open'
  ;
```

Attributes configuration:

```yaml
study_id:
  number:
    all: true
    multiple: single
session_type: 
  text: 
    all: true
    multiple: single
    disabled: false
```
