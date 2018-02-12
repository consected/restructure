require 'rails_helper'

RSpec.describe AppType, type: :model do

  include ModelSupport

  it "creates a new application type" do

    create_admin
    res = AppType.create!(name: 'test', label:'Test App', current_admin: @admin)
    expect(res).to be_a AppType

  end

end
