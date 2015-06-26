require 'rails_helper'

RSpec.describe "protocol_events/show", type: :view do
  before(:each) do
    @protocol_event = assign(:protocol_event, ProtocolEvent.create!(
      :name => "Name",
      :protocol => nil,
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
