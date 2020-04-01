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

  def setup_deidentifier
    @al_name = AlFilterTestName

    aldef = ActivityLog.active.where(name: @al_name).first
    unless aldef
      aldef = ActivityLog.where(name: @al_name).first
      aldef.update(disabled: false, current_admin: @admin)
      aldef = ActivityLog.active.where(name: @al_name).first
      puts 'About to fail' unless aldef
    end
    expect(aldef).not_to be nil

    aldef.extra_log_types = <<EOF
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

    aldef.current_admin = @admin
    aldef.save!
  end
end
