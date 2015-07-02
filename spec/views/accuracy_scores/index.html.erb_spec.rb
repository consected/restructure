require 'rails_helper'

RSpec.describe "accuracy_scores/index", type: :view do
  before(:each) do
    assign(:accuracy_scores, [
      AccuracyScore.create!(
        :name => "Name",
        :value => 1,
        :admin => nil
      ),
      AccuracyScore.create!(
        :name => "Name",
        :value => 1,
        :admin => nil
      )
    ])
  end

  it "renders a list of accuracy_scores" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
