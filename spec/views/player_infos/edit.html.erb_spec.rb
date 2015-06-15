require 'rails_helper'

RSpec.describe "player_infos/edit", type: :view do
  before(:each) do
    @player_info = assign(:player_info, PlayerInfo.create!(
      :master => nil,
      :first_name => "MyString",
      :last_name => "MyString",
      :middle_name => "MyString",
      :nick_name => "MyString",
      :occupation_category => "MyString",
      :company => "MyString",
      :company_description => "MyString",
      :transaction_status => "MyString",
      :transaction_substatus => "MyString",
      :website => "MyString",
      :alternate_website => "MyString",
      :twitter_id => "MyString",
      :user => nil
    ))
  end

  it "renders the edit player_info form" do
    render

    assert_select "form[action=?][method=?]", player_info_path(@player_info), "post" do

      assert_select "input#player_info_master_id[name=?]", "player_info[master_id]"

      assert_select "input#player_info_first_name[name=?]", "player_info[first_name]"

      assert_select "input#player_info_last_name[name=?]", "player_info[last_name]"

      assert_select "input#player_info_middle_name[name=?]", "player_info[middle_name]"

      assert_select "input#player_info_nick_name[name=?]", "player_info[nick_name]"

      assert_select "input#player_info_occupation_category[name=?]", "player_info[occupation_category]"

      assert_select "input#player_info_company[name=?]", "player_info[company]"

      assert_select "input#player_info_company_description[name=?]", "player_info[company_description]"

      assert_select "input#player_info_transaction_status[name=?]", "player_info[transaction_status]"

      assert_select "input#player_info_transaction_substatus[name=?]", "player_info[transaction_substatus]"

      assert_select "input#player_info_website[name=?]", "player_info[website]"

      assert_select "input#player_info_alternate_website[name=?]", "player_info[alternate_website]"

      assert_select "input#player_info_twitter_id[name=?]", "player_info[twitter_id]"

      assert_select "input#player_info_user_id[name=?]", "player_info[user_id]"
    end
  end
end
