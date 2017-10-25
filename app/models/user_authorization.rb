class UserAuthorization < ActiveRecord::Base
  include AdminHandler
  belongs_to :user

  validate :correct_authorization


  def self.authorizations
    [:export_csv, :export_json, :create_msid, :view_reports, :view_external_links, :edit_report_data, :import_csv]    
  end

  def self.user_can? user, auth

    self.active.where(user_id: user.id, has_authorization: auth.to_s).first

  end

  private
    def correct_authorization
      if self.user.nil? || self.user.id.nil?
        errors.add :user, "must be set"
      elsif has_authorization.nil? || !self.class.authorizations.include?(self.has_authorization.to_sym)
        errors.add :has_authorization, "is an invalid value"
      else
        res = self.class.user_can? self.user, self.has_authorization
        if res && res.id != self.id # If the user has the authorization set and it is not this record
          errors.add :user, "already has the authorization #{self.has_authorization}"
        end
      end

    end

end
