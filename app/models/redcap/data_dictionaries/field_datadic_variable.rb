# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Store the field definition to a datadic variable
    class FieldDatadicVariable
      MatchingAttribs = %i[form name label label_note annotation is_required
                           valid_type valid_min valid_max is_identifier label_plain label_note_plain
                           data_dictionary field_type field_choices
                           source_name checkbox_choice_fields
                           storage_type db_or_fs schema_or_path table_or_file
                           position section sub_section title_plain].freeze

      attr_accessor(*MatchingAttribs)

      def initialize(field)
        MatchingAttribs.each do |m|
          send("#{m}=", field.send(m))
        end
      end

      #
      # Get the variable instance from the identifying information provided,
      # by searching for the variable name within the set
      # of variables for the specified form.
      # @return [Datadic::Variable | nil]
      def self.find_by_identifiers(source_name:,
                                   form_name:,
                                   variable_name:,
                                   redcap_data_dictionary:,
                                   source_type: :redcap)

        Datadic::Variable.active.where(source_name: source_name,
                                       source_type: source_type,
                                       form_name: form_name,
                                       variable_name: variable_name,
                                       redcap_data_dictionary: redcap_data_dictionary)
      end

      #
      # Current admin to support updates
      # @return [Admin]
      def current_admin
        data_dictionary.current_admin
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
        self.class.find_by_identifiers(**identified_by).first&.id
      end

      #
      # Map the REDCap field definition to a partial data dictionary definition
      # @return [Hash]
      def partial_datadic_definition
        {
          study: data_dictionary.study,
          presentation_type: field_type.presentation_type,
          label: label_plain,
          label_note: label_note_plain,
          annotation: annotation,
          is_required: is_required,
          valid_type: valid_type,
          valid_min: valid_min,
          valid_max: valid_max,
          multi_valid_choices: field_choices.choices(plain_text: true),
          is_identifier: is_identifier,
          storage_type: storage_type,
          db_or_fs: db_or_fs,
          schema_or_path: schema_or_path,
          table_or_file: table_or_file,
          position: position,
          section_id: id_from_name(section),
          sub_section_id: id_from_name(sub_section),
          title: title_plain
        }
      end

      def datadic_defaults
        {
          variable_type: field_type.default_variable_type
        }
      end

      def identifiers
        {
          source_name: source_name,
          source_type: :redcap,
          form_name: form.name,
          variable_name: name,
          redcap_data_dictionary: data_dictionary
        }
      end

      #
      # Refresh variable records (Datadic::Variable) based on
      # current definition. For this field representation we check for an existing record
      # matching on the source, form and field. If one is there, we check if a partial definition
      # is matched, the source (Redcap) definition of the data dictionary variable. If it
      # is then nothing is changed. If there has been a change then we update with the changes
      # from the Redcap definition. If there was no record, we create one, with the Redcap definition
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
          stored_variable = simple_variable_record_create

          return unless checkbox_choice_fields

          checkbox_choice_fields.each do |fn|
            simple_variable_record_create checkbox_choice_overrides(fn, stored_variable)
          end
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
      # This is simple if the field type is not checkbox, a simple update is made.
      # If the field type is a checkbox, then we need to add fields for the checkbox choices
      # and make associations between them and the main field definition.
      # @param [Datadic::Variable] stored_variable - record to update
      def variable_record_update(stored_variable)
        Datadic::Variable.transaction do
          stored_variable.update! partial_datadic_definition.merge(current_admin: current_admin)
          return unless checkbox_choice_fields

          # Get existing records that are listed as #also_equivalent_to the base variable record
          # ensuring only those items that follow the checkbox field naming are picked.
          # We don't want to mess with records that have been added through other mechanisms that
          # are associated with this.
          aet = stored_variable.also_equivalent_to.active.where('variable_name ~ :like_var', like_var: "#{name}___.+")
          current_choice_fields = aet.pluck(:variable_name)
          configured_choice_fields = checkbox_choice_fields.map(&:to_s)

          new_choice_fields = configured_choice_fields - current_choice_fields
          del_choice_fields = current_choice_fields - configured_choice_fields
          matched_choice_fields = current_choice_fields & configured_choice_fields

          # For new checkbox choice fields, create them
          new_choice_fields.each do |fn|
            simple_variable_record_create checkbox_choice_overrides(fn, stored_variable)
          end

          # For deleted checkbox choice fields, disable them
          Datadic::Variable.active.where(identifiers.merge(variable_name: del_choice_fields)).update_all(disabled: true)

          # For matched checkbox choice fields, update them
          matched_choice_fields.each do |fn|
            data = partial_datadic_definition
                   .merge(datadic_defaults)
                   .merge(current_admin: current_admin)

            update_rec = Datadic::Variable.active.where(identifiers.merge(variable_name: fn)).first
            update_rec.update! data
          end
        end
      end

      def checkbox_choice_overrides(new_variable_name, equivalent_to_variable)
        {
          variable_name: new_variable_name,
          equivalent_to_id: equivalent_to_variable&.id,
          variable_type: FieldType::FieldToVariableTypes[:checkbox_choice],
          presentation_type: FieldType.presentation_type_for(field_type.name, 'choice')
        }
      end
    end
  end
end
