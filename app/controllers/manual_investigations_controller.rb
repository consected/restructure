class ManualInvestigationsController < ApplicationController
  include MasterHandler

  private
    
    def secure_params
      params.require(:manual_investigation).permit(:fill_in_addresses, :in_survey, :verify_survey_participation, :verify_player_and_or_match, :accuracy, :accuracy_score, :accruedseasons, :first_contract, :second_contract, :third_contract, :changed, :changed_column, :verified, :pilotq1, :mailing, :outreach_vfy, :insert_audit_key, :user_id)
    end
end
