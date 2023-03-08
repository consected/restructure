# frozen_string_literal: true

module Redcap
  #
  # Each request to the API is recorded in the table for audit. Additionally,
  # background Redcap record storage is also captured.
  class ClientRequest < Admin::AdminBase
    include AdminHandler

    self.table_name = 'redcap_client_requests'

    belongs_to :redcap_project_admin, class_name: 'Redcap::ProjectAdmin'

    validates :server_url, presence: true
    validates :name, presence: true
    validates :action, presence: true

    attr_accessor :disabled

    scope :limited_index, -> { limit 1000 }
  end
end
