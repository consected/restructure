# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Categorical selection choices for a field
    class FieldDatadicChoices
      MatchingAttribs = %i[name select_choices_string_from_def field
                           source_name data_dictionary choices_plain_text].freeze

      attr_accessor(*MatchingAttribs)

      def initialize(field)
        MatchingAttribs.each do |m|
          send("#{m}=", field.send(m))
        end
      end

      #
      # Current admin to support updates
      # @return [Admin]
      def current_admin
        data_dictionary.current_admin
      end

      #
      # Refresh choices records (Datadic::Choice) based on
      # current definition. For each choice in the representation, we check for an existing record
      # matching on the source, form, field and value. If there is one and the label matches, then
      # there is no change. If the label doesn't match then we update the record. If no record was
      # found, then we create one. For this field we disable any items that were not matched exactly,
      # updated or created, since they are no longer in use.
      # @return [<Type>] <description>
      def refresh_choices_records
        return if choices_plain_text.empty?

        all_stored_choices = []

        choices_plain_text.each do |choice|
          label = choice.last
          value = choice.first
          data = {
            source_name: source_name,
            source_type: :redcap,
            form_name: field.form.name,
            field_name: field.name,
            value: value,
            redcap_data_dictionary: data_dictionary
          }

          stored_choice = Datadic::Choice.active.where(data).first
          if stored_choice&.label == label
            nil
          elsif stored_choice
            stored_choice.update! label: label, current_admin: current_admin
          else
            data[:label] = label
            data[:current_admin] = current_admin
            stored_choice = Datadic::Choice.create!(data)
          end
          all_stored_choices << stored_choice
        end

        all_stored_choices_ids = all_stored_choices.map(&:id)

        # Now disable any remaining stored choices that are no longer in the configuration
        # for this field
        Datadic::Choice.active
                       .where(
                         redcap_data_dictionary: data_dictionary,
                         form_name: field.form.name,
                         field_name: field.name
                       )
                       .where.not(id: all_stored_choices_ids)
                       .update_all(disabled: true)
      end
    end
  end
end
