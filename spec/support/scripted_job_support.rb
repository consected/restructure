# frozen_string_literal: true

module ScriptedJobSupport
  AlFilterTestName = 'AL Filter Test 2'

  def setup_scripted_job
    @al_name = AlFilterTestName

    @aldef = ActivityLog.active.where(name: @al_name).first
    unless @aldef
      @aldef = ActivityLog.where(name: @al_name).first
      @aldef.update(disabled: false, current_admin: @admin)
      @aldef = ActivityLog.active.where(name: @al_name).first
      puts 'About to fail' unless @aldef
    end
    expect(@aldef).not_to be nil

    @aldef.extra_log_types = <<~ENDDEF
      scripted_test:
        label: Scripted Test
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
                - scripted:
                    - file_filters: .*
                      recursive: true
                      set_tags:
                        '0010,0010': '{{master_id}}'
                        '0010,0020': '{{player_contacts.data}}'

          pipeline:
            - mount_archive:
            - index_files:

            - scripted:
                - file_filters: 00000.?.dcm
                  script_filename: simple_job_script.sh
                  args:
                    - container_file_path
                - file_filters: 000003.dcm
                  script_filename: dicom_job_script.sh
                  args:
                    - container_file_path


    ENDDEF

    @aldef.current_admin = @admin
    @aldef.save!
    @aldef.option_configs(force: true)
    ActivityLog::PlayerContactPhone.definition.option_configs(force: true)

    finalize_al_setup activity: :scripted_test
  end

  # def user_access_scripted_job
  #   @resource_name = ActivityLog::PlayerContactPhone.definition.option_type_config_for(:scripted_test).resource_name
  #   expect(@resource_name).to eq 'activity_log__player_contact_phone__scripted_test'

  #   setup_access :activity_log__player_contact_phone__scripted_test, resource_type: :activity_log_type, user: @user
  #   create_filter('.*', resource_name: 'activity_log__player_contact_phone__scripted_test', role_name: nil)
  # end

  def create_scripted_activity
    @activity_log = ActivityLog::PlayerContactPhone.new(
      select_call_direction: 'from player',
      select_who: 'user',
      extra_log_type: :scripted_test,
      player_contact: @player_contact,
      master: @player_contact.master
    )

    @activity_log.save!
    expect(@activity_log.resource_name).to eq 'activity_log__player_contact_phone__scripted_test'
    @activity_log
  end
end
