class AddUserPreferencesToPreviouslyCreatedUsers < ActiveRecord::Migration[5.2]
  def up
    User.where.not(first_name: nil, last_name: nil).where.not('email LIKE :template', template: Settings::TemplateUserEmailPatternForSQL).each do |user|
      user.user_preference
      user.save!
    end
  end

  def down; end
end
