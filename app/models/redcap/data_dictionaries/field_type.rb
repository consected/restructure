# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Field type functionality for the data dictionaries
    class FieldType
      ValidFieldTypes = %i[
        text
        text_area
        calc
        dropdown
        radio
        checkbox
        yesno
        truefalse
        file
        slider
        descriptive
      ].freeze

      attr_accessor :name, :select_choices_string_from_def, :field

      def initialize(field, field_type_name)
        field_metadata = field.def_metadata
        self.field = field
        self.name = field_type_name.to_sym
        self.select_choices_string_from_def = field_metadata[:select_choices_or_calculations]
      end

      def to_s
        name.to_s
      end

      #
      # Get a list of selections using the
      # string value for :select_choices_or_calculations in a field definition.
      # The result is an array of fields (to ensure original ordering),
      # with each item being a two element array of strings.
      # By default, we return:
      #   [<value>, <label>]
      # If the option rails_format: true then we return
      #   [<label>, <value>]
      # @param [Boolean] plain_text - strip HTML tags and common entities
      # @param [Boolean] rails_format - return as [label, value]
      # @return [Array{Array}]
      def choices(plain_text: nil, rails_format: nil)
        select_choices_string_from_def.split('|').map do |i|
          items = i.split(',', 2)
          label = items.last.strip
          label = if plain_text
                    Redcap::Utilities.html_to_plain_text(label)
                  else
                    label.html_safe
                  end

          value = items.first.strip
          if rails_format
            [label, value]
          else
            [value, label]
          end
        end
      end

      #
      # Shortcut to the owning data dictionary
      # @return [Redcap::DataDictionary]
      def data_dictionary
        field.form.data_dictionary
      end

      #
      # The source name for data items is the server domain name
      # @return [String] <description>
      def source_name
        data_dictionary.source_name
      end

      #
      # Current admin to support updates
      # @return [Admin]
      def current_admin
        data_dictionary.current_admin
      end

      def refresh_choices_records
        return if choices.empty?

        all_stored_choices = []

        choices(plain_text: true).each do |choice|
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
