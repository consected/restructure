# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Categorical selection choices for a field
    class FieldChoices
      attr_accessor :name, :select_choices_string_from_def, :field

      def initialize(field)
        field_metadata = field.def_metadata
        self.field = field
        self.select_choices_string_from_def = field_metadata[:select_choices_or_calculations]
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
        return unless select_choices_string_from_def

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

      def choices_plain_text
        choices(plain_text: true)
      end

      #
      # Return an array of the choices values
      # @return [Array{String}]
      def choices_values
        choices.map(&:first)
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
      # Refresh choices records (Datadic::Choice) based on
      # current definition. For each choice in the representation, we check for an existing record
      # matching on the source, form, field and value. If there is one and the label matches, then
      # there is no change. If the label doesn't match then we update the record. If no record was
      # found, then we create one. For this field we disable any items that were not matched exactly,
      # updated or created, since they are no longer in use.
      # @return [<Type>] <description>
      def refresh_choices_records
        return if choices.empty?

        FieldDatadicChoices.new(self).refresh_choices_records
      end

      #
      # Generate a select choices string "val, Label | val2, Label 2 | ..." from an
      # array of [[val, label], [...], ...]
      # Formatted exactly like Redcap definition
      # @param [Array{Array}] choices_array
      # @return [String]
      def self.select_choices_string_from(choices_array)
        choices_array.map { |i| i.join(', ') }.join(' | ')
      end
    end
  end
end
