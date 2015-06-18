require 'rails_helper'

RSpec.describe "item_flag_names/new", type: :view do
  before(:each) do
    assign(:item_flag_name, ItemFlagName.new(
      :name => "MyString",
      :user => nil
    ))
  end

  it "renders new item_flag_name form" do
    render

    assert_select "form[action=?][method=?]", item_flag_names_path, "post" do

      assert_select "input#item_flag_name_name[name=?]", "item_flag_name[name]"

      assert_select "input#item_flag_name_user_id[name=?]", "item_flag_name[user_id]"
    end
  end
end
