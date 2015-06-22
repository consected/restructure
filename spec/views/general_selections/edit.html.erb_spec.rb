require 'rails_helper'

RSpec.describe "general_selections/edit", type: :view do
  before(:each) do
    @general_selection = assign(:general_selection, GeneralSelection.create!(
      :name => "MyString",
      :value => "MyString",
      :item_type => "MyString"
    ))
  end

  it "renders the edit general_selection form" do
    render

    assert_select "form[action=?][method=?]", general_selection_path(@general_selection), "post" do

      assert_select "input#general_selection_name[name=?]", "general_selection[name]"

      assert_select "input#general_selection_value[name=?]", "general_selection[value]"

      assert_select "input#general_selection_item_type[name=?]", "general_selection[item_type]"
    end
  end
end
