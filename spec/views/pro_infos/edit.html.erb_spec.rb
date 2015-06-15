require 'rails_helper'

RSpec.describe "pro_infos/edit", type: :view do
  before(:each) do
    @pro_info = assign(:pro_info, ProInfo.create!(
      :master => nil,
      :user => nil
    ))
  end

  it "renders the edit pro_info form" do
    render

    assert_select "form[action=?][method=?]", pro_info_path(@pro_info), "post" do

      assert_select "input#pro_info_master_id[name=?]", "pro_info[master_id]"

      assert_select "input#pro_info_user_id[name=?]", "pro_info[user_id]"
    end
  end
end
