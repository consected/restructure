require 'rails_helper'

RSpec.describe "imports/index", type: :view do
  before(:each) do
    assign(:imports, [
      Import.create!(
        :primary_table => "Primary Table",
        :item_count => 2,
        :filename => "Filename",
        :items => "",
        :user => nil
      ),
      Import.create!(
        :primary_table => "Primary Table",
        :item_count => 2,
        :filename => "Filename",
        :items => "",
        :user => nil
      )
    ])
  end

  it "renders a list of imports" do
    render
    assert_select "tr>td", :text => "Primary Table".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Filename".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
