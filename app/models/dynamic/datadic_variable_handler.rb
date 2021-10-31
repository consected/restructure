# frozen_string_literal: true

module Dynamic
  #
  # Store the field definition to a datadic variable
  module DatadicVariableHandler
    extend ActiveSupport::Concern

    # Each class including this module must have a constant defined
    # MatchingAttribs = %i[].freeze

    included do
      attr_accessor(*self::MatchingAttribs)
    end

    class_methods do
      def self.owner_identifier
        nil
      end

      def source_type
        :data
      end

      #
      # Get the variable instance from the identifying information provided,
      # by searching for the variable name within the set
      # of variables for the specified form.
      # @return [Datadic::Variable | nil]
      def find_by_identifiers(source_name:,
                              form_name:,
                              variable_name:,
                              source_type:,
                              owner: nil)

        conditions = {
          source_name: source_name,
          source_type: source_type,
          form_name: form_name,
          variable_name: variable_name
        }

        conditions[owner_identifier] = owner if owner_identifier

        Datadic::Variable.active.where(conditions)
      end
    end

    #
    # Initialize the instance so that it can be stored to a Datadic::Variable.
    # The MatchingAttribs are copied from the *field* instance passed to #new
    # allowing each of the underlying values to be used.
    # The *field* argument is typically a
    # Redcap::DataDictionaries::Field - the metadata for a field retrieved from Redcap
    # NOTE: this initialize method may be overidden
    def initialize(field)
      self.class::MatchingAttribs.each do |m|
        send("#{m}=", field.send(m))
      end
    end

    #
    # Current admin to support updates
    # @return [Admin]
    def current_admin
      owner.current_admin
    end

    #
    # Get the variable instance from the variable name we have been provided,
    # by searching for the variable name within the current set
    # of variables for this form.
    # @param [String | Symbol] var_name
    # @return [Datadic::Variable | nil]
    def id_from_name(var_name)
      return unless var_name

      identified_by = identifiers.dup
      identified_by[:variable_name] = var_name
      identified_by[:owner] = identified_by.delete(self.class.owner_identifier) if self.class.owner_identifier
      self.class.find_by_identifiers(**identified_by).first&.id
    end

    #
    # Map the source field definition to a partial data dictionary definition
    # @return [Hash]
    def partial_datadic_definition
      {
        study: study,
        domain: domain,
        presentation_type: presentation_type,
        label: label_plain,
        label_note: label_note_plain,
        annotation: annotation,
        is_required: is_required,
        valid_type: valid_type,
        valid_min: valid_min,
        valid_max: valid_max,
        multi_valid_choices: field_choices_plain_text,
        is_identifier: is_identifier,
        is_derived_var: is_derived_var,
        owner_email: owner_email,
        storage_type: storage_type,
        db_or_fs: db_or_fs,
        schema_or_path: schema_or_path,
        table_or_file: table_or_file,
        storage_varname: name,
        position: position,
        section_id: id_from_name(section),
        sub_section_id: id_from_name(sub_section),
        title: title_plain
      }
    end

    def datadic_defaults
      {
        variable_type: default_variable_type
      }
    end

    def identifiers
      ids = {
        source_name: source_name,
        source_type: source_type,
        form_name: form_name,
        variable_name: name
      }

      ids[self.class.owner_identifier] = owner if self.class.owner_identifier
      ids
    end

    #
    # Refresh variable records (Datadic::Variable) based on
    # current definition. For this field representation we check for an existing record
    # matching on the source, form and field. If one is there, we check if a partial definition
    # is matched, the source definition of the data dictionary variable. If it
    # is then nothing is changed. If there has been a change then we update with the changes
    # from the source definition. If there was no record, we create one, with the source definition
    # and some additional defaults.
    # @return [Integer] - number of updates
    def refresh_variable_record
      updates = 0
      stored_variables = Datadic::Variable.active.where(identifiers)

      raise FphsException, "multiple variables found for #{identifiers.to_json}" if stored_variables.count > 1

      if stored_variables.count == 1
        # We found a corresponding variable record. Check if it needs to be updated
        matched_stored_variable = stored_variables.where(partial_datadic_definition)

        if matched_stored_variable.count.positive?
          # This was found as a direct match. Nothing to do
          nil
        else
          # No direct match found. Update the original items
          variable_record_update(stored_variables.first)
          updates += 1
        end
      else

        variable_record_create
        updates += 1
      end

      updates
    end

    private

    #
    # Create a new variable record definition.
    # This is simple if the field type is not checkbox, a simple creation is made.
    # If the field type is a checkbox, then we need to add fields for the checkbox choices
    # and make associations between them and the main field definition.
    def variable_record_create
      Datadic::Variable.transaction do
        simple_variable_record_create
      end
    end

    #
    # Create a single variable record definition, optionally overriding values
    # @param [Hash | nil] with_overrides - hash of attributes to override the defaults with
    # @return [Datadic::Variable] - created record
    def simple_variable_record_create(with_overrides = nil)
      data = partial_datadic_definition
             .merge(identifiers)
             .merge(datadic_defaults)
             .merge(current_admin: current_admin)

      data.merge!(with_overrides) if with_overrides

      Datadic::Variable.create!(data)
    end

    #
    # Update a variable record definition.
    # @param [Datadic::Variable] stored_variable - record to update
    def variable_record_update(stored_variable)
      Datadic::Variable.transaction do
        stored_variable.update! partial_datadic_definition.merge(current_admin: current_admin)
      end
    end
  end
end
