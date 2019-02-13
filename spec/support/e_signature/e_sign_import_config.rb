module ESignImportConfig

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
    files = %w(create_al_table.sql create_ipa_inex_checklist_table.sql)

    files.each do |fn|

      begin
        sqlfn = Rails.root.join('db', 'app_specific', 'test_esign', fn)
        puts "Running psql: #{sqlfn}"
        `PGOPTIONS=--search_path=ml_app psql -d fpa_test < #{sqlfn}`
      rescue ActiveRecord::StatementInvalid => e
        puts "Exception due to PG error?... #{e}"
      end
    end


    create_admin
    create_user

    Admin::AppType.import_config File.read(Rails.root.join('db', 'app_configs', 'test esign_config.json')), @admin

    # Make sure the activity log configuration is available

    # Admin::UserAccessControl.active.update_all(disabled: true)

    new_app_type = Admin::AppType.where(name: 'test esign').first
    new_app_type.update!(disabled: false, current_admin: @admin)
    new_app_type
  end


  def setup_access_as role

    app_name = 'test esign'
    @app_type = Admin::AppType.active.where(name: app_name).first
    enable_user_app_access app_name, @user
    @user.update!(app_type: @app_type)
    # Ensure we have adequate access controls
    add_user_to_role role

  end

end
