require 'rails_helper'

RSpec.describe "accuracy_scores/show", type: :view do
  before(:each) do
    @accuracy_score = assign(:accuracy_score, AccuracyScore.create!(
      :name => "Name",
      :value => 1,
      :admin => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/1/)
    expect(rendered).to match(//)
  end
end
