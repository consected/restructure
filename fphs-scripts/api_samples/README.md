# API Samples

## Upload a file to an IPA subject

Run `upload-to-subject.sh` with variables like this:

    upload_server="https://files-internal.fphs2.harvard.edu" \
    upload_user_email=api_file_upload_client@app.fphs2.harvard.edu \
    upload_user_token=jovgSjpRKT46ihGejWGGc6su23bxEA \
    upload_app_type=3 \
    ipa_id=45754 \
    session_type=mri \
    upload_filename=123457_persnet.pdf \
    upload_file=/home/phil/Downloads/123457_persnet.pdf \
    fphs-scripts/api_samples/upload-to-subject.sh
