require 'rails_helper'

RSpec.describe "protocol_events/index", type: :view do
  before(:each) do
    assign(:protocol_events, [
      ProtocolEvent.create!(
        :name => "Name",
        :protocol => nil,
        :user => nil
      ),
      ProtocolEvent.create!(
        :name => "Name",
        :protocol => nil,
        :user => nil
      )
    ])
  end

  it "renders a list of protocol_events" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
