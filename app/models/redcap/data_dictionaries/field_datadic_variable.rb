# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Interface to methods for storign a field definition to a data dictionary
    # as a Datadic::Variable record
    # Called from Recap::DataDictionaries::Field, with matching attributes to pass through
    # This class overrides some of the standard methods in Dynamic::DatadicVariableHandler
    # to handle Redcap choice fields effectively
    class FieldDatadicVariable
      MatchingAttribs = %i[form name label label_note annotation is_required
                           valid_type valid_min valid_max is_identifier label_plain label_note_plain
                           owner field_type field_choices_plain_text
                           source_name checkbox_choice_fields
                           storage_type db_or_fs schema_or_path table_or_file
                           position section sub_section title_plain
                           presentation_type default_variable_type form_name study
                           owner_email].freeze

      include Dynamic::DatadicVariableHandler

      def self.owner_identifier
        :redcap_data_dictionary
      end

      def source_type
        :redcap
      end

      def domain
        form&.name || name
      end

      def is_derived_var
        false
      end

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
          storage_varname: new_variable_name,
          equivalent_to_id: equivalent_to_variable&.id,
          variable_type: FieldType::FieldToVariableTypes[:checkbox_choice],
          presentation_type: FieldType.presentation_type_for(field_type.name, 'choice')
        }
      end
    end
  end
end
