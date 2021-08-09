module Redcap
  #
  # Persisted project user record
  class ProjectUser < Admin::AdminBase
    self.table_name = 'redcap_project_users'
    include AdminHandler

    belongs_to :redcap_project_admin,
               class_name: 'Redcap::ProjectAdmin',
               foreign_key: :redcap_project_admin_id,
               inverse_of: :redcap_project_users
  end
end
