require 'rails_helper'

RSpec.describe "manage_users/index", type: :view do
  before(:each) do
    assign(:manage_users, [
      ManageUser.create!(),
      ManageUser.create!()
    ])
  end

  it "renders a list of manage_users" do
    render
  end
end
