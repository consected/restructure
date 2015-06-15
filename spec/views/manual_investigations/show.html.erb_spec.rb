require 'rails_helper'

RSpec.describe "manual_investigations/show", type: :view do
  before(:each) do
    @manual_investigation = assign(:manual_investigation, ManualInvestigation.create!(
      :fill_in_addresses => "Fill In Addresses",
      :in_survey => "In Survey",
      :verify_survey_participation => "Verify Survey Participation",
      :verify_player_and_or_match => "Verify Player And Or Match",
      :accuracy => "Accuracy",
      :accuracy_score => 1,
      :accruedseasons => "9.99",
      :first_contract => "First Contract",
      :second_contract => "Second Contract",
      :third_contract => "Third Contract",
      :changed => 2,
      :changed_column => "Changed Column",
      :verified => 3,
      :pilotq1 => 4,
      :mailing => 5,
      :outreach_vfy => 6,
      :insert_audit_key => 7,
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Fill In Addresses/)
    expect(rendered).to match(/In Survey/)
    expect(rendered).to match(/Verify Survey Participation/)
    expect(rendered).to match(/Verify Player And Or Match/)
    expect(rendered).to match(/Accuracy/)
    expect(rendered).to match(/1/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/First Contract/)
    expect(rendered).to match(/Second Contract/)
    expect(rendered).to match(/Third Contract/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Changed Column/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/6/)
    expect(rendered).to match(/7/)
    expect(rendered).to match(//)
  end
end
