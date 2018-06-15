module BhsImportConfig

  include MasterSupport

  def import_config

    seed_database

    # Ensure we are set up for this test
    res = File.read("#{ENV['HOME']}/.pgpass").include? 'fpa_test'
    expect(res).to be true

    q = ActiveRecord::Base.connection.execute "select * from pg_catalog.pg_roles where rolname='fphsetl'"
    res = q.ntuples
    expect(res).to eq 1

    # Setup the triggers, functions, etc
    files = %w(DROP-bhs_tables.sql 1-create_bhs_assignments_external_identifier.sql 2-create_activity_log.sql 3-add_notification_triggers.sql 4-add_testmybrain_trigger.sql 5-create_sync_subject_data_aws_db.sql 6-grant_roles_access_to_ml_app.sql)

    files.each do |fn|

      begin
        sqlfn = Rails.root.join('db', 'app_specific', 'bhs', 'aws-db', fn)
        puts "Running psql: #{sqlfn}"
        `PGOPTIONS=--search_path=ml_app psql -d fpa_test < #{sqlfn}`
      rescue ActiveRecord::StatementInvalid => e
        puts "Exception due to PG error?... #{e}"
      end
    end


    create_admin
    create_user

    Admin::AppType.import_config File.read(Rails.root.join('db', 'app_configs', 'bhs_config.json')), @admin

    # Make sure the activity log configuration is available

    ExternalIdentifier.where(name: 'bhs_assignments').update_all(disabled: true)
    i = ExternalIdentifier.where(name: 'bhs_assignments').order(id: :desc).first
    i.update! disabled: false, min_id: 0, external_id_edit_pattern: nil, current_admin: @admin if i

    ActivityLog.where(table_name: 'activity_log_bhs_assignments').update_all(disabled: true)
    i = ActivityLog.where(table_name: 'activity_log_bhs_assignments').order(id: :desc).first
    i.update! disabled: false, current_admin: @admin if i
    ::ActivityLog.define_models
    ::ExternalIdentifier.define_models

    Admin::AppType.where(name: 'bhs').first.update!(disabled: false, current_admin: @admin)
  end

end
