# frozen_string_literal: true

module Dynamic
  #
  # Interface to methods for storign a field definition to a data dictionary
  # as a Datadic::Variable record
  # Called from Dynamic::DynamicModelField, with matching attributes to pass through
  class DatadicVariable
    MatchingAttribs = DynamicModelField::MatchingAttribs

    include Dynamic::DatadicVariableHandler

    def self.owner_identifier
      nil
    end
  end
end
