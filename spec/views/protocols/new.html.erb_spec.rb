require 'rails_helper'

RSpec.describe "protocols/new", type: :view do
  before(:each) do
    assign(:protocol, Protocol.new(
      :name => "MyString",
      :user => nil
    ))
  end

  it "renders new protocol form" do
    render

    assert_select "form[action=?][method=?]", protocols_path, "post" do

      assert_select "input#protocol_name[name=?]", "protocol[name]"

      assert_select "input#protocol_user_id[name=?]", "protocol[user_id]"
    end
  end
end
