require 'rails_helper'

RSpec.describe "player_infos/index", type: :view do
  before(:each) do
    assign(:player_infos, [
      PlayerInfo.create!(
        :master => nil,
        :first_name => "First Name",
        :last_name => "Last Name",
        :middle_name => "Middle Name",
        :nick_name => "Nick Name",
        :occupation_category => "Occupation Category",
        :company => "Company",
        :company_description => "Company Description",
        :transaction_status => "Transaction Status",
        :transaction_substatus => "Transaction Substatus",
        :website => "Website",
        :alternate_website => "Alternate Website",
        :twitter_id => "Twitter",
        :user => nil
      ),
      PlayerInfo.create!(
        :master => nil,
        :first_name => "First Name",
        :last_name => "Last Name",
        :middle_name => "Middle Name",
        :nick_name => "Nick Name",
        :occupation_category => "Occupation Category",
        :company => "Company",
        :company_description => "Company Description",
        :transaction_status => "Transaction Status",
        :transaction_substatus => "Transaction Substatus",
        :website => "Website",
        :alternate_website => "Alternate Website",
        :twitter_id => "Twitter",
        :user => nil
      )
    ])
  end

  it "renders a list of player_infos" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "First Name".to_s, :count => 2
    assert_select "tr>td", :text => "Last Name".to_s, :count => 2
    assert_select "tr>td", :text => "Middle Name".to_s, :count => 2
    assert_select "tr>td", :text => "Nick Name".to_s, :count => 2
    assert_select "tr>td", :text => "Occupation Category".to_s, :count => 2
    assert_select "tr>td", :text => "Company".to_s, :count => 2
    assert_select "tr>td", :text => "Company Description".to_s, :count => 2
    assert_select "tr>td", :text => "Transaction Status".to_s, :count => 2
    assert_select "tr>td", :text => "Transaction Substatus".to_s, :count => 2
    assert_select "tr>td", :text => "Website".to_s, :count => 2
    assert_select "tr>td", :text => "Alternate Website".to_s, :count => 2
    assert_select "tr>td", :text => "Twitter".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
