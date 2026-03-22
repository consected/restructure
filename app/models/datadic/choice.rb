# frozen_string_literal: true

module Datadic
  #
  # Direct access to the Redcap gem api_client, set up with details from a ProjectAdmin record
  # Each request to the API is recorded in the table for audit
  class Choice < Admin::AdminBase
    self.table_name = 'datadic_choices'
    include AdminHandler

    belongs_to :redcap_data_dictionary, class_name: 'Redcap::DataDictionary'

    def self.human_name
      'Data Dictionary Variable Choice'
    end

    def self.resource_category
      :data_dictionary
    end

    add_model_to_list
  end
end
