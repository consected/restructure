require 'rails_helper'

RSpec.describe Admin::AppConfiguration, type: :model do

  include ModelSupport

  it "Adds an item to a configuration with non-blank app type" do

    create_admin
    create_user
    app_type = @user.app_type

    Admin::AppConfiguration.remove_user_config @user, app_type, 'notes field caption', @admin
    Admin::AppConfiguration.remove_default_config app_type, 'notes field caption', @admin

    res = Admin::AppConfiguration.value_for :notes_field_config, @user
    expect(res).to be nil

    res = Admin::AppConfiguration.value_for :notes_field_config
    expect(res).to be nil

    expect {
      Admin::AppConfiguration.add_default_config app_type, 'some test config', 'a value', @admin
    }.to raise_error FphsException

    res = Admin::AppConfiguration.add_default_config app_type, 'notes field caption', 'a value', @admin
    expect(res).to be_a Admin::AppConfiguration

    res = Admin::AppConfiguration.value_for :notes_field_caption, @user
    expect(res).to eq 'a value'

    res = Admin::AppConfiguration.add_user_config @user, app_type, 'notes field caption', 'user value', @admin
    expect(res).to be_a Admin::AppConfiguration

    
    res = Admin::AppConfiguration.value_for :notes_field_caption, @user
    expect(res).to eq 'user value'

  end

end
