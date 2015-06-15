require 'rails_helper'

RSpec.describe "manage_users/new", type: :view do
  before(:each) do
    assign(:manage_user, ManageUser.new())
  end

  it "renders new manage_user form" do
    render

    assert_select "form[action=?][method=?]", manage_users_path, "post" do
    end
  end
end
