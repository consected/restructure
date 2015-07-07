class AccuracyScoresController < ApplicationController
  include AdminControllerHandler


  private
    def secure_params
      params.require(:accuracy_score).permit(:name, :value, :disabled)
    end
end
