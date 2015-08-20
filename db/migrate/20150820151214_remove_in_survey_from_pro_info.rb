class RemoveInSurveyFromProInfo < ActiveRecord::Migration
  def change
    remove_column :pro_infos, :in_survey, :string
  end
end
