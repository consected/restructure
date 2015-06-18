require 'rails_helper'

RSpec.describe "item_flag_names/index", type: :view do
  before(:each) do
    assign(:item_flag_names, [
      ItemFlagName.create!(
        :name => "Name",
        :user => nil
      ),
      ItemFlagName.create!(
        :name => "Name",
        :user => nil
      )
    ])
  end

  it "renders a list of item_flag_names" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
