require 'rails_helper'

RSpec.describe "protocol_events/edit", type: :view do
  before(:each) do
    @protocol_event = assign(:protocol_event, ProtocolEvent.create!(
      :name => "MyString",
      :protocol => nil,
      :user => nil
    ))
  end

  it "renders the edit protocol_event form" do
    render

    assert_select "form[action=?][method=?]", protocol_event_path(@protocol_event), "post" do

      assert_select "input#protocol_event_name[name=?]", "protocol_event[name]"

      assert_select "input#protocol_event_protocol_id[name=?]", "protocol_event[protocol_id]"

      assert_select "input#protocol_event_user_id[name=?]", "protocol_event[user_id]"
    end
  end
end
