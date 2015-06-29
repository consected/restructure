require 'rails_helper'

RSpec.describe "protocol_outcomes/show", type: :view do
  before(:each) do
    @protocol_outcome = assign(:protocol_outcome, ProtocolOutcome.create!(
      :name => "Name",
      :protocol => nil,
      :admin => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
