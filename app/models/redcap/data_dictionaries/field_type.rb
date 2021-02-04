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

      attr_accessor :name, :select_choices_string_from_def

      def initialize(field, field_type_name)
        field_metadata = field.def_metadata
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
    end
  end
end
