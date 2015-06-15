require 'rails_helper'

RSpec.describe "manual_investigations/edit", type: :view do
  before(:each) do
    @manual_investigation = assign(:manual_investigation, ManualInvestigation.create!(
      :fill_in_addresses => "MyString",
      :in_survey => "MyString",
      :verify_survey_participation => "MyString",
      :verify_player_and_or_match => "MyString",
      :accuracy => "MyString",
      :accuracy_score => 1,
      :accruedseasons => "9.99",
      :first_contract => "MyString",
      :second_contract => "MyString",
      :third_contract => "MyString",
      :changed => 1,
      :changed_column => "MyString",
      :verified => 1,
      :pilotq1 => 1,
      :mailing => 1,
      :outreach_vfy => 1,
      :insert_audit_key => 1,
      :user => nil
    ))
  end

  it "renders the edit manual_investigation form" do
    render

    assert_select "form[action=?][method=?]", manual_investigation_path(@manual_investigation), "post" do

      assert_select "input#manual_investigation_fill_in_addresses[name=?]", "manual_investigation[fill_in_addresses]"

      assert_select "input#manual_investigation_in_survey[name=?]", "manual_investigation[in_survey]"

      assert_select "input#manual_investigation_verify_survey_participation[name=?]", "manual_investigation[verify_survey_participation]"

      assert_select "input#manual_investigation_verify_player_and_or_match[name=?]", "manual_investigation[verify_player_and_or_match]"

      assert_select "input#manual_investigation_accuracy[name=?]", "manual_investigation[accuracy]"

      assert_select "input#manual_investigation_accuracy_score[name=?]", "manual_investigation[accuracy_score]"

      assert_select "input#manual_investigation_accruedseasons[name=?]", "manual_investigation[accruedseasons]"

      assert_select "input#manual_investigation_first_contract[name=?]", "manual_investigation[first_contract]"

      assert_select "input#manual_investigation_second_contract[name=?]", "manual_investigation[second_contract]"

      assert_select "input#manual_investigation_third_contract[name=?]", "manual_investigation[third_contract]"

      assert_select "input#manual_investigation_changed[name=?]", "manual_investigation[changed]"

      assert_select "input#manual_investigation_changed_column[name=?]", "manual_investigation[changed_column]"

      assert_select "input#manual_investigation_verified[name=?]", "manual_investigation[verified]"

      assert_select "input#manual_investigation_pilotq1[name=?]", "manual_investigation[pilotq1]"

      assert_select "input#manual_investigation_mailing[name=?]", "manual_investigation[mailing]"

      assert_select "input#manual_investigation_outreach_vfy[name=?]", "manual_investigation[outreach_vfy]"

      assert_select "input#manual_investigation_insert_audit_key[name=?]", "manual_investigation[insert_audit_key]"

      assert_select "input#manual_investigation_user_id[name=?]", "manual_investigation[user_id]"
    end
  end
end
