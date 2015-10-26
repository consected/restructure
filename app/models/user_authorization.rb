class UserAuthorization < ActiveRecord::Base
  include AdminHandler
  belongs_to :user

  def self.authorizations
    [:export_csv, :export_json, :create_msid, :view_reports, :view_external_links]    
  end

  def self.user_can? user, auth

    !!self.active.where(user_id: user.id, has_authorization: auth.to_s).first

  end

end
  
