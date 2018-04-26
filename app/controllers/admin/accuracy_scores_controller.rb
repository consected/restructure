class Admin::AccuracyScoresController < AdminController

  private
    def permitted_params
      [:name, :value, :disabled]
    end
end
