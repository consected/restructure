require 'rails_helper'

RSpec.describe AppConfiguration, type: :model do

  include ModelSupport

  it "Adds an item to a configuration with blank app type" do

    create_admin
    app_type_id = AppType.active.first.id

    res = AppConfiguration.create! name: 'some test config', value: 'a value', app_type_id: app_type_id, current_admin: @admin
    expect(res).to be_a AppConfiguration

    res = AppConfiguration.value_for :some_test_config, app_type_id: app_type_id, current_admin: @admin
    expect(res).to eq 'a value'

  end

end
