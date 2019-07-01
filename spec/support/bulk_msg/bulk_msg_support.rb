module BulkMsgSupport


  def import_bulk_msg_app
    @admin, _ = create_admin unless @admin
    # Setup the triggers, functions, etc
    files = %w(bulk/create_al_bulk_messages.sql bulk/create_zeus_bulk_messages_table.sql bulk/dup_check_recipients.sql bulk/create_zeus_bulk_message_recipients_table.sql bulk/create_zeus_bulk_message_statuses.sql bulk/setup_master.sql 0-scripts/z_grant_roles.sql)


    files.each do |fn|
      `psql -d fpa_test -c "create schema if not exists bulk_msg;"`
      begin
        sqlfn = Rails.root.join('db', 'app_specific', 'bulk-msg', 'aws-db', fn)
        puts "Running psql: #{sqlfn}"
        `PGOPTIONS=--search_path=bulk_msg,ml_app psql -d fpa_test < #{sqlfn}`
      rescue ActiveRecord::StatementInvalid => e
        puts "Exception due to PG error?... #{e}"
      end
    end

    config = File.read Rails.root.join('db/app_configs/bulk-msg_config.json')

    Admin::AppType.import_config(config, @admin)
  end


end
