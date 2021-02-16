# frozen_string_literal: true

module Datadic
  #
  # Direct access to the Redcap gem api_client, set up with details from a ProjectAdmin record
  # Each request to the API is recorded in the table for audit
  class Variable < Admin::AdminBase
    include AdminHandler

    self.table_name = 'datadic_variables'

    belongs_to :redcap_data_dictionary, class_name: 'Redcap::DataDictionary'
    belongs_to :equivalent_to, class_name: 'Datadic::Variable', optional: true
    has_many :also_equivalent_to, class_name: 'Datadic::Variable', foreign_key: :equivalent_to_id
  end
end
