# API Samples

## Upload a file to an IPA subject

Medusa Filestore requires multiple API calls to perform an upload to a specific assessment session container for a subject.
The script `upload-to-subject.sh` handles through a single command line call, hiding the complexity from the caller.

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

    upload_server="https://files-internal.fphs2.harvard.edu" \
    upload_user_email=api_file_upload_client@app.fphs2.harvard.edu \
    upload_user_token=jovgSjpRKT46ihGejWGGc6su23bxEA \
    upload_app_type=3 \
    ipa_id=45754 \
    session_type=mri \
    upload_filename=12-07-1999-AbdomenAbdomenPETCT-15740.zip \
    upload_file=/home/phil/Downloads//Link\ to\ Head-Neck\ Cetuximab-Demo/12-07-1999-AbdomenAbdomenPETCT-15740.zip \
    fphs-scripts/api_samples/upload-to-subject.sh

The variables are:

- **upload_server** : The base URL for the server
- **upload_user_email** : Username for authentication
- **upload_user_token** : Secret token for authentication
- **upload_app_type** : Numeric id for the app (Medusa - IPA Files)
- **ipa_id** : Subject's numeric id unique to the IPA study
- **session_type** : Short name for the assessment session type
- **upload_filename** : The filename to be presented to end-users after upload
- **upload_file** : Full path to the file to be uploaded
