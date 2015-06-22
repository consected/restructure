require 'rails_helper'

RSpec.describe "general_selections/new", type: :view do
  before(:each) do
    assign(:general_selection, GeneralSelection.new(
      :name => "MyString",
      :value => "MyString",
      :item_type => "MyString"
    ))
  end

  it "renders new general_selection form" do
    render

    assert_select "form[action=?][method=?]", general_selections_path, "post" do

      assert_select "input#general_selection_name[name=?]", "general_selection[name]"

      assert_select "input#general_selection_value[name=?]", "general_selection[value]"

      assert_select "input#general_selection_item_type[name=?]", "general_selection[item_type]"
    end
  end
end
