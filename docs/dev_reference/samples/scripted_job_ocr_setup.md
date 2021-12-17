# Scripted Job OCR Setup

Filestore scripted jobs can be run immediately after upload of a file, or on demand by a user. The following
example shows how to run OCR on a PDF triggered by a "user file action".

The scripted job calls a bash script `<app_root>/scripted_job_scripts/ocr_pdf.sh` that performs the cleanup and
OCR of a PDF document containing scanned images, such as a scanned or faxed document. The result is returned in
a new PDF file with the OCR text in a layer underneath the image, making the document searchable.

To setup the Activity Log, add an activity something like this:

```yaml
ocr:
  label: OCR

  nfs_store:
    user_file_actions:
      - name: OCR PDF
        pipeline:
          - scripted:
              - file_filters:
                  - \.pdf
                script_filename: ocr_pdf.sh
                args:
                  - container_file_path
                  - '-ocr'
                  - '--deskew'
                  # For noisy images, changing 
                  # this to "--clean --deskew" can help
                  # but will significantly slow down the process.
                fail_silently: false
                timeout: 3600
                on_success:
                  store_files:
                    to_same_path_as_source: true
```

