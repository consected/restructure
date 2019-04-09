# API Samples

Medusa Filestore provides an API that can be called directly with curl. It reflects the JSON API used by the app user interface, allowing complex requirements to be met. In order to simplify the use of the API, several scripts have been provided that compose the numerous API calls into meaningful end-user actions.

## Authentication

Authentication to the API is through a username / secret token pair, passed as URL parameters (or optionally form parameters for POST requests.) These authentication credentials
are supplied by an administrator, along with other essential defaults.

In an API call by HTTP the following parameters are used for authentication:

- **user_email** : username
- **user_token** : shared secret
- **use_app_type** : app id for which access is requested

In the following example scripts, these parameters (and certain other defaults) are sourced as environment variables from the file `api_credentials.sh`.
Update this file and ensure to make it readable only by the operating system user responsible for calling the API with something like `chmod 600 api_credentials.sh`

The API functions and resources that can be accessed are configured on the server by the administrator. These access controls are limited to the expected requirements of the
API user. If specific functionality is not available that is required, please contact the app administrator to extend the API access.


## Create a container to store assessment files for an IPA subject

Medusa Filestore requires multiple API calls to create a storage container for assessment files. The script `create-container.sh` performs the
necessary calls through a single command line call, hiding the complexity from the caller.

The API calls made perform the following:

- Checks if the container already exists
- Get the unique master record identifier for the IPA subject, based on the IPA id
- Create a container with the requested session type in the master record

### Calling the script

The script is called with command line environment variables like this:

    ipa_id=999999990 \
    session_type=mri \
    fphs-scripts/api_samples/create-container.sh


The variables are:

- **ipa_id** : Subject's numeric id unique to the IPA study
- **session_type** : Short name for the assessment session type

### Result

The result should be a long JSON string, starting something like this:

    {"activity_log__ipa_assignment_session_filestore":{"id":16,"master_id":20,"ipa_assignment_id":null,"select_type":null,"operator":null,"session_date":null,"session_time":null,"notes":"","extra_log_type":"mri","user_id":32,"created_at":"2019-04-09T11:34:07.699Z","updated_at":"2019-04-09T11:34:07.699Z","select_status":"open","select_confirm_status":null,"item_id":null,"item_type":"activity_log__ipa_assignment_session_filestore","updated_at_ts":1554809647,"created_at_ts":1554809647,"data":"MRI / Liver MR",...

The returned information is not necessary for use in other API calls, such as uploading a file to the new container, and can be discarded.

Any unsuccessful results return exit code 1.


## Upload a file to an IPA subject

Medusa Filestore requires multiple API calls to perform an upload to a specific assessment session container for a subject.
The script `upload-to-subject.sh` handles this through a single command line call.

The procedure behind the scenes is:

- Get the unique container identifier for the specified subject and session type
- Check if the specified file is uploadable
    - the user has permission
    - the filename matches defined filters
    - the filename does not already exist in the container
- Upload the file as a single chunk
  - curl shows a progress bar for uploads
  - Check MD5 hashes are correct
  - Complete storage to secure filesystem
- Return a success result and results file `upload-result.txt`

Note that the command line script does not support chunked uploads. A failure during upload will require the file to be uploaded from the beginning, and does not support the restart feature that is provided in the web browser user interface.

### Calling the script

The script is called with command line environment variables like this:

    ipa_id=999999990 \
    session_type=mri \
    upload_filename=12-07-1999-AbdomenAbdomenPETCT-15740.zip \
    upload_file=/home/phil/Downloads//Link\ to\ Head-Neck\ Cetuximab-Demo/12-07-1999-AbdomenAbdomenPETCT-15740.zip \
    fphs-scripts/api_samples/upload-to-subject.sh

The variables are:

- **api_server** : The base URL for the server
- **api_username** : Username for authentication
- **api_user_token** : Secret token for authentication
- **app_type** : Numeric id for the app (Medusa - IPA Files)
- **report_id** : Report identifier for finding subject's container details
- **ipa_id** : Subject's numeric id unique to the IPA study
- **session_type** : Short name for the assessment session type
- **upload_filename** : The filename to be presented to end-users after upload
- **upload_file** : Full path to the file to be uploaded

### Result

A successful upload returns a JSON string with basic information about the upload, such as:

    {"file":{"name":"12-07-1999-AbdomenAbdomenPETCT-15740.zip","size":101466729,"hash":"368fee394979a8f1602058f2e6bf13c9","url":"/nfs_store/downloads/10"}}

Any unsuccessful results should return exit code 1. Additional information should be echoed to stdout.

### Performance

In tests, files up to 4.3GB in size were uploaded through this script. For the largest (4.3GB) files the total time to complete was approximately 75 minutes on a 9Mbps (upstream) broadband connection.

If required, larger files can be uploaded. Testing has shown that the server is not memory bound, although additional disk space may need to be allocated to the server to accomodate significantly larger uploads.
