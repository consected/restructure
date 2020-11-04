class Admin::AccuracyScoresController < AdminController
  protected

  def primary_model
    Classification::AccuracyScore
  end

  private

  def permitted_params
    %i[name value disabled]
  end
end
