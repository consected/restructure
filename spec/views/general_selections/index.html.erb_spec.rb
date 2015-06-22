require 'rails_helper'

RSpec.describe "general_selections/index", type: :view do
  before(:each) do
    assign(:general_selections, [
      GeneralSelection.create!(
        :name => "Name",
        :value => "Value",
        :item_type => "Item Type"
      ),
      GeneralSelection.create!(
        :name => "Name",
        :value => "Value",
        :item_type => "Item Type"
      )
    ])
  end

  it "renders a list of general_selections" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Value".to_s, :count => 2
    assert_select "tr>td", :text => "Item Type".to_s, :count => 2
  end
end
