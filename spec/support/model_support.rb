# frozen_string_literal: true

require "#{Rails.root}/spec/support/seed_support"
require "#{Rails.root}/spec/support/user_support"

module ModelSupport
  include ::UserSupport

  def seed_database
    Rails.logger.info 'Starting seed setup in Model Support'
    # puts "#{Time.now} Starting seed setup in Model Support"
    SeedSupport.setup
  end

  def db_name
    ActiveRecord::Base.connection.current_database
  end

  def pick_one_from(objs)
    objs[rand objs.length]
  end

  def create_app_type(name: nil, label: nil)
    Admin::AppType.create! current_admin: @admin, name:, label:
  end

  def add_app_config(app_type, name, value, user: nil, role_name: nil)
    @admin, = create_admin unless @admin

    cond = { name: }
    cond[:role_name] = role_name if role_name
    cond[:user] = user if user

    ac = app_type.app_configurations.active.where(cond).first
    if ac
      cond[:current_admin] = @admin
      ac.update! cond
    else
      cond = cond.merge(current_admin: @admin, app_type:, value:)
      Admin::AppConfiguration.create! cond
    end
  end

  def cleanup_matching_activity_logs(item_type, rec_type, process_name, excluding_id: nil)
    ActivityLogSupport.cleanup_matching_activity_logs(item_type, rec_type, process_name, excluding_id:)
  end

  def random_phone_number
    pn = "(617)123-1234 c#{rand 1_000_000_000}"
    pn = random_phone_number while PlayerContact.where(data: pn).count > 0
    pn
  end
end
