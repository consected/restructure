# frozen_string_literal: true

require "#{::Rails.root}/spec/support/seed_support"
require "#{::Rails.root}/spec/support/user_support"

module ModelSupport
  include ::UserSupport

  def seed_database
    Rails.logger.info 'Starting seed setup in Model Support'
    SeedSupport.setup
  end

  def db_name
<<<<<<< HEAD
<<<<<<< HEAD
    ActiveRecord::Base.connection.current_database
=======
    "fpa_test#{ENV['TEST_ENV_NUMBER']}"
>>>>>>> 65d7808... Baseline code
=======
    ActiveRecord::Base.connection.current_database
>>>>>>> ba15603... Get db name automatically
  end

  def pick_one_from(objs)
    objs[rand objs.length]
  end

  def create_app_type(name: nil, label: nil)
    Admin::AppType.create! current_admin: @admin, name: name, label: label
  end

  def add_app_config(app_type, name, value, user: nil, role_name: nil)
    @admin ||= create_admin

    cond = { name: name }
    cond[:role_name] = role_name if role_name
    cond[:user] = user if user

    ac = app_type.app_configurations.active.where(cond).first
    if ac
      cond[:current_admin] = @admin
      ac.update! cond
    else
      cond = cond.merge(current_admin: @admin, app_type: app_type, value: value)
      Admin::AppConfiguration.create! cond
    end
  end

  # Force a database seed at config time, to avoid issues later
  Rails.logger.info 'Starting seed setup in setup of Master Support'
  SeedSupport.setup
end
