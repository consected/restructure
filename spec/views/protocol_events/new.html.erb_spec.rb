require 'rails_helper'

RSpec.describe "protocol_events/new", type: :view do
  before(:each) do
    assign(:protocol_event, ProtocolEvent.new(
      :name => "MyString",
      :protocol => nil,
      :user => nil
    ))
  end

  it "renders new protocol_event form" do
    render

    assert_select "form[action=?][method=?]", protocol_events_path, "post" do

      assert_select "input#protocol_event_name[name=?]", "protocol_event[name]"

      assert_select "input#protocol_event_protocol_id[name=?]", "protocol_event[protocol_id]"

      assert_select "input#protocol_event_user_id[name=?]", "protocol_event[user_id]"
    end
  end
end
