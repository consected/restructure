class Admin::AccuracyScoresController < AdminController

  protected

    def primary_model
      Classification::AccuracyScore
    end

  private
    def permitted_params
      [:name, :value, :disabled]
    end
end
