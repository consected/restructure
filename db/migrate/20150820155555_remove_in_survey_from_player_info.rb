class RemoveInSurveyFromPlayerInfo < ActiveRecord::Migration
  def change
    remove_column :player_infos, :in_survey, :string
  end
end
