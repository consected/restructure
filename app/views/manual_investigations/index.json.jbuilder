json.array!(@manual_investigations) do |manual_investigation|
  json.extract! manual_investigation, :id, :fill_in_addresses, :in_survey, :verify_survey_participation, :verify_player_and_or_match, :accuracy, :accuracy_score, :accruedseasons, :first_contract, :second_contract, :third_contract, :changed, :changed_column, :verified, :pilotq1, :mailing, :outreach_vfy, :insert_audit_key, :user_id
  json.url manual_investigation_url(manual_investigation, format: :json)
end
