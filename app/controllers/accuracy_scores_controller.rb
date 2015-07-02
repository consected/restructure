class AccuracyScoresController < ApplicationController
  include AdminHandler


  private
    def secure_params
      params.require(:accuracy_score).permit(:name, :value, :admin_id)
    end
end
