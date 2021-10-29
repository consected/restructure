# frozen_string_literal: true

module Datadic
  #
  # Represent a
  class Variable < Admin::AdminBase
    include AdminHandler

    self.table_name = 'datadic_variables'

    belongs_to :redcap_data_dictionary, class_name: 'Redcap::DataDictionary', optional: true
    belongs_to :equivalent_to, class_name: 'Datadic::Variable', optional: true
    has_many :also_equivalent_to, class_name: 'Datadic::Variable', foreign_key: :equivalent_to_id

    def self.human_name
      'Data Dictionary Variable'
    end

    def self.resource_category
      :data_dictionary
    end

    add_model_to_list
  end
end
