# frozen_string_literal: true

module DicomSupport
  AlFilterTestName = 'AL Filter Test 2'

  def test_dicom_files
    (0..9).map { |i| "00000#{i}.dcm" }
  end

  def dicom_file_path(f)
    File.join('spec', 'fixtures', 'files', 'dicom', f).to_s
  end

  def upload_test_dicom_files
    @uploaded_files = []
    test_dicom_files.each do |f|
      dicom_content = File.read(dicom_file_path(f))
      @uploaded_files << upload_file(f, dicom_content)
    end
    @uploaded_files
  end

  def upload_test_zip_file
    f = 'dicoms.zip'
    @uploaded_files = []
    file_content = File.read(dicom_file_path(f))
    @uploaded_files << upload_file(f, file_content)
  end

  def setup_deidentifier
    @al_name = AlFilterTestName

    @aldef = ActivityLog.active.where(name: @al_name).first
    unless @aldef
      @aldef = ActivityLog.where(name: @al_name).first
      @aldef.update(disabled: false, current_admin: @admin)
      @aldef = ActivityLog.active.where(name: @al_name).first
      puts 'About to fail' unless @aldef
    end
    expect(@aldef).not_to be nil

    @aldef.extra_log_types = <<EOF
    step_1:
      label: Step 1
      fields:
        - select_call_direction
        - select_who

      save_trigger:
        on_create:
          create_filestore_container:
            name:
              - session files
              - select_scanner
            label: Session Files
            create_with_role: nfs_store group 600

        on_upload:
          notify:
            type: email
            role: upload notify role
            layout_template: test email layout upload
            content_template: test email content upload
            subject: Send test

      references:
        nfs_store__manage__container:
          label: Files
          from: this
          add: one_to_this
          view_as:
            edit: hide
            show: filestore
            new: not_embedded

      nfs_store:

        user_file_actions:
          - name: Re-Identify
            pipeline:
              - dicom_deidentify:
                  - file_filters: .*
                    recursive: true
                    set_tags:
                      '0010,0010': '{{master_id}}'
                      '0010,0020': '{{player_contacts.data}}'
              - dicom_metadata:
          - name: Re-Identify and Copy
            id: reidentify_copy
            pipeline:
              - dicom_deidentify:
                  - file_filters: .*
                    recursive: true
                    new_path: copy-location
                    set_tags:
                      '0010,0010': '{{master_id}}'
                      '0010,0020': '{{player_contacts.data}}'
              - dicom_metadata:
          - name: Re-Run Pipeline
            id: rerun_pipeline
            pipeline:
              - rerun_all:

          - name: Check File Handling for Disabled User
            id: disable_check
            pipeline:
              - dicom_deidentify:
                - file_filters: make_copy_2.dcm
                  recursive: true
                  new_path: copied-file-2
                  set_tags:
                    '0010,0010': moved 2
                    '0010,0020': moved 2 again


        pipeline:
          - mount_archive:
          - index_files:

          - dicom_deidentify:
              - file_filters: .*
                recursive: true
                set_tags:
                  '0010,0010': new value
                  '0010,0020': another tagval
                delete_tags:
                  - '0010,1010'
              - file_filters: substitute.dcm
                recursive: true
                set_tags:
                  '0010,0010': do nothing - {{master_id}}
                  '0010,0020': do nothing tagval - {{player_contacts.data}}
                  '0008,103E': got the activity - {{parent_item.data}}
              - file_filters: make_copy.dcm
                recursive: true
                new_path: copied-file
                set_tags:
                  '0010,0010': moved
                  '0010,0020': moved again

          - dicom_metadata:

    step_2:
      label: Step 2
      fields:
        - select_call_direction
        - select_who

      save_trigger:
        on_create:
          create_filestore_container:
            name:
              - session files
              - select_scanner
            label: Session Files
            create_with_role: nfs_store group 600

        on_upload:
          notify:
            type: email
            role: upload notify role
            layout_template: test email layout upload
            content_template: test email content upload
            subject: Send test

      references:
        nfs_store__manage__container:
          label: Files
          from: this
          add: one_to_this
          view_as:
            edit: hide
            show: filestore
            new: not_embedded

EOF

    @aldef.current_admin = @admin
    @aldef.save!
    @aldef.option_configs(force: true)
    ActivityLog::PlayerContactPhone.definition.option_configs(force: true)

    finalize_al_setup
  end
end
