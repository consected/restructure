require 'rails_helper'

RSpec.describe "manage_users/show", type: :view do
  before(:each) do
    @manage_user = assign(:manage_user, ManageUser.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
