require 'rails_helper'

RSpec.describe Admin::AppConfiguration, type: :model do

  include ModelSupport

  it "Adds an item to a configuration with non-blank app type" do

    create_admin
    create_user
    app_type_id = @user.app_type_id

    res = Admin::AppConfiguration.create! name: 'some test config', value: 'a value', app_type_id: app_type_id, current_admin: @admin
    expect(res).to be_a Admin::AppConfiguration

    res = Admin::AppConfiguration.value_for :some_test_config, @user
    expect(res).to eq 'a value'

    res = Admin::AppConfiguration.create! name: 'some test config', value: 'user value', app_type_id: app_type_id, current_admin: @admin, user: @user
    expect(res).to be_a Admin::AppConfiguration

    res = Admin::AppConfiguration.value_for :some_test_config, @user
    expect(res).to eq 'user value'

  end

end
