require 'rails_helper'

RSpec.describe "addresses/edit", type: :view do
  before(:each) do
    @address = assign(:address, Address.create!(
      :master => nil,
      :street => "MyString",
      :street2 => "MyString",
      :street3 => "MyString",
      :city => "MyString",
      :state => "MyString",
      :zip => "MyString",
      :source => "MyString",
      :rank => 1,
      :type => "",
      :user => nil
    ))
  end

  it "renders the edit address form" do
    render

    assert_select "form[action=?][method=?]", address_path(@address), "post" do

      assert_select "input#address_master_id[name=?]", "address[master_id]"

      assert_select "input#address_street[name=?]", "address[street]"

      assert_select "input#address_street2[name=?]", "address[street2]"

      assert_select "input#address_street3[name=?]", "address[street3]"

      assert_select "input#address_city[name=?]", "address[city]"

      assert_select "input#address_state[name=?]", "address[state]"

      assert_select "input#address_zip[name=?]", "address[zip]"

      assert_select "input#address_source[name=?]", "address[source]"

      assert_select "input#address_rank[name=?]", "address[rank]"

      assert_select "input#address_type[name=?]", "address[type]"

      assert_select "input#address_user_id[name=?]", "address[user_id]"
    end
  end
end
