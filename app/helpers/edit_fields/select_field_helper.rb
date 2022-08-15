# frozen_string_literal: true

module EditFields
  module SelectFieldHelper
    #
    # Gets the #data for each record for a select on an association or class name
    # @param [UserBase] form_object_instance the current instance for the form object
    # @param [String] assoc_or_class_name a master association name or an underscored class name to select from
    # @param [Symbol] value_attr names the attribute to be returned as the value of a selection - default :data
    # @param [String | nil] group_split_char optionally specifies the character to split groups of results
    # @param [true] no_assoc states that we should ignore any associations and just use the class name to find data
    # @return [Array(String, Array(Array, Array))] a human name string and a list of data from the matched records
    def list_record_data_for_select(form_object_instance, assoc_or_class_name,
                                    value_attr: :data, label_attr: :data, group_split_char: nil,
                                    no_assoc: nil)
      EditFields::SelectFieldHandler.list_record_data_for_select(form_object_instance,
                                                                 assoc_or_class_name,
                                                                 value_attr: value_attr,
                                                                 label_attr: label_attr,
                                                                 group_split_char: group_split_char,
                                                                 no_assoc: no_assoc)
    end

    #
    # Group selections based on splitting on the *group_split_char*
    # If the split character is not specified, just return the original array
    # @param [Array] reslist - a standard select options array
    # @param [String | nil] group_split_char
    # @return [Array] - a standard select options array
    def record_results_grouping(reslist, group_split_char)
      EditFields::SelectFieldHandler.record_results_grouping(reslist, group_split_char)
    end
  end
end
