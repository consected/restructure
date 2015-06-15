require 'rails_helper'

RSpec.describe "addresses/index", type: :view do
  before(:each) do
    assign(:addresses, [
      Address.create!(
        :master => nil,
        :street => "Street",
        :street2 => "Street2",
        :street3 => "Street3",
        :city => "City",
        :state => "State",
        :zip => "Zip",
        :source => "Source",
        :rank => 1,
        :type => "Type",
        :user => nil
      ),
      Address.create!(
        :master => nil,
        :street => "Street",
        :street2 => "Street2",
        :street3 => "Street3",
        :city => "City",
        :state => "State",
        :zip => "Zip",
        :source => "Source",
        :rank => 1,
        :type => "Type",
        :user => nil
      )
    ])
  end

  it "renders a list of addresses" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Street".to_s, :count => 2
    assert_select "tr>td", :text => "Street2".to_s, :count => 2
    assert_select "tr>td", :text => "Street3".to_s, :count => 2
    assert_select "tr>td", :text => "City".to_s, :count => 2
    assert_select "tr>td", :text => "State".to_s, :count => 2
    assert_select "tr>td", :text => "Zip".to_s, :count => 2
    assert_select "tr>td", :text => "Source".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Type".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
