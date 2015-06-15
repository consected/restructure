require 'rails_helper'

RSpec.describe "player_infos/show", type: :view do
  before(:each) do
    @player_info = assign(:player_info, PlayerInfo.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/First Name/)
    expect(rendered).to match(/Last Name/)
    expect(rendered).to match(/Middle Name/)
    expect(rendered).to match(/Nick Name/)
    expect(rendered).to match(/Occupation Category/)
    expect(rendered).to match(/Company/)
    expect(rendered).to match(/Company Description/)
    expect(rendered).to match(/Transaction Status/)
    expect(rendered).to match(/Transaction Substatus/)
    expect(rendered).to match(/Website/)
    expect(rendered).to match(/Alternate Website/)
    expect(rendered).to match(/Twitter/)
    expect(rendered).to match(//)
  end
end
