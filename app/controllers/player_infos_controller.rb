class PlayerInfosController < ApplicationController
  include MasterHandler

  private
    
    def secure_params
      params.require(:player_info).permit(:master_id, :first_name, :last_name, :middle_name, :nick_name, :birth_date, :death_date, :start_year, :end_year, :rank, :occupation_category, :company, :company_description, :transaction_status, :transaction_substatus, :user_id, :college, :source, :notes)
    end
end
