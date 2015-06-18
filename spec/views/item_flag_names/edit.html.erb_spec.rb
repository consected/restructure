require 'rails_helper'

RSpec.describe "item_flag_names/edit", type: :view do
  before(:each) do
    @item_flag_name = assign(:item_flag_name, ItemFlagName.create!(
      :name => "MyString",
      :user => nil
    ))
  end

  it "renders the edit item_flag_name form" do
    render

    assert_select "form[action=?][method=?]", item_flag_name_path(@item_flag_name), "post" do

      assert_select "input#item_flag_name_name[name=?]", "item_flag_name[name]"

      assert_select "input#item_flag_name_user_id[name=?]", "item_flag_name[user_id]"
    end
  end
end
