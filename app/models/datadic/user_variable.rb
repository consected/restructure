# frozen_string_literal: true

module Datadic
  #
  # Represent a data dictionary variable
  # Used by authorized users
  # An equivalent class Variable provides admin access to the same table.
  class UserVariable < UserBase
    self.table_name = 'datadic_variables'

    def self.no_master_association
      true
    end

    include UserHandler

    belongs_to :redcap_data_dictionary, class_name: 'Redcap::DataDictionary', optional: true
    belongs_to :equivalent_to, class_name: 'Datadic::Variable', optional: true
    has_many :also_equivalent_to, class_name: 'Datadic::Variable', foreign_key: :equivalent_to_id

    attr_accessor :current_user

    def self.human_name
      'Data Dictionary Variable'
    end

    def self.resource_category
      :data_dictionary
    end

    def self.resource_name
      :datadic_variables
    end

    add_model_to_list
  end
end
