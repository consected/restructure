require 'rails_helper'

RSpec.describe "trackers/index", type: :view do
  before(:each) do
    assign(:trackers, [
      Tracker.create!(
        :master => nil,
        :protocol => nil,
        :event => "Event",
        :c_method => "C Method",
        :outcome => "Outcome",
        :user => nil
      ),
      Tracker.create!(
        :master => nil,
        :protocol => nil,
        :event => "Event",
        :c_method => "C Method",
        :outcome => "Outcome",
        :user => nil
      )
    ])
  end

  it "renders a list of trackers" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Event".to_s, :count => 2
    assert_select "tr>td", :text => "C Method".to_s, :count => 2
    assert_select "tr>td", :text => "Outcome".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
