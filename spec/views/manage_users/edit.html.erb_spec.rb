require 'rails_helper'

RSpec.describe "manage_users/edit", type: :view do
  before(:each) do
    @manage_user = assign(:manage_user, ManageUser.create!())
  end

  it "renders the edit manage_user form" do
    render

    assert_select "form[action=?][method=?]", manage_user_path(@manage_user), "post" do
    end
  end
end
