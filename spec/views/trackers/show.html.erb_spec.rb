require 'rails_helper'

RSpec.describe "trackers/show", type: :view do
  before(:each) do
    @tracker = assign(:tracker, Tracker.create!(
      :master => nil,
      :protocol => nil,
      :event => "Event",
      :c_method => "C Method",
      :outcome => "Outcome",
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Event/)
    expect(rendered).to match(/C Method/)
    expect(rendered).to match(/Outcome/)
    expect(rendered).to match(//)
  end
end
