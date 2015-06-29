require 'rails_helper'

RSpec.describe "protocol_outcomes/index", type: :view do
  before(:each) do
    assign(:protocol_outcomes, [
      ProtocolOutcome.create!(
        :name => "Name",
        :protocol => nil,
        :admin => nil
      ),
      ProtocolOutcome.create!(
        :name => "Name",
        :protocol => nil,
        :admin => nil
      )
    ])
  end

  it "renders a list of protocol_outcomes" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
