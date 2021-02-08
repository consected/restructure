# frozen_string_literal: true

module Redcap
  #
  # Direct access to the Redcap gem client, set up with details from a ProjectAdmin record
  # Each request to the API is recorded in the table for audit
  class ClientRequest < Admin::AdminBase
    include AdminHandler

    self.table_name = 'redcap_client_requests'

    belongs_to :redcap_project_admin, class_name: 'Redcap::ProjectAdmin'

    validates :server_url, presence: true
    validates :name, presence: true
    validates :action, presence: true

    attr_accessor :disabled
  end
end
