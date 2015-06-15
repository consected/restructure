require 'rails_helper'

RSpec.describe "manual_investigations/index", type: :view do
  before(:each) do
    assign(:manual_investigations, [
      ManualInvestigation.create!(
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
      ),
      ManualInvestigation.create!(
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
      )
    ])
  end

  it "renders a list of manual_investigations" do
    render
    assert_select "tr>td", :text => "Fill In Addresses".to_s, :count => 2
    assert_select "tr>td", :text => "In Survey".to_s, :count => 2
    assert_select "tr>td", :text => "Verify Survey Participation".to_s, :count => 2
    assert_select "tr>td", :text => "Verify Player And Or Match".to_s, :count => 2
    assert_select "tr>td", :text => "Accuracy".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "9.99".to_s, :count => 2
    assert_select "tr>td", :text => "First Contract".to_s, :count => 2
    assert_select "tr>td", :text => "Second Contract".to_s, :count => 2
    assert_select "tr>td", :text => "Third Contract".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Changed Column".to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => 4.to_s, :count => 2
    assert_select "tr>td", :text => 5.to_s, :count => 2
    assert_select "tr>td", :text => 6.to_s, :count => 2
    assert_select "tr>td", :text => 7.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
