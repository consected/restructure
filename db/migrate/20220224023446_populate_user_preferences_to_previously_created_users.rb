class PopulateUserPreferencesToPreviouslyCreatedUsers < ActiveRecord::Migration[5.2]
  def up
    User.where.not(first_name: nil, last_name: nil).where.not('email LIKE :template', template: Settings::TemplateUserEmailPatternForSQL).each do |user|
      user.user_preference
      user.user_preference.force_save!
      user.save!
    end
  end
end
