require 'rails_helper'

RSpec.describe "pro_infos/new", type: :view do
  before(:each) do
    assign(:pro_info, ProInfo.new(
      :master => nil,
      :user => nil
    ))
  end

  it "renders new pro_info form" do
    render

    assert_select "form[action=?][method=?]", pro_infos_path, "post" do

      assert_select "input#pro_info_master_id[name=?]", "pro_info[master_id]"

      assert_select "input#pro_info_user_id[name=?]", "pro_info[user_id]"
    end
  end
end
