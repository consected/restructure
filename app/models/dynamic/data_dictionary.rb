# frozen_string_literal: true

module Dynamic
  class DataDictionary
    include OptionsHandler

    # Fields hash of Fields::Field
    configure_hash :fields, with: %i[type label caption comment no_downcase]

    attr_accessor :dynamic_model

    def initialize(dynamic_model)
      @dynamic_model = dynamic_model

      setup_fields_from_config
    end

    def setup_fields_from_config
      f = {
        fields: {}
      }
      dynamic_model.table_columns.each do |col|
        name = col.name
        f[:fields][name] ||= {}
        f[:fields][name].merge! field_config_for(col)
      end

      setup_options_hash(f, :fields)
    end

    def self.core_field_names
      %w[id user_id created_at updated_at disabled master_id]
    end

    def default_options
      dynamic_model.default_options
    end

    def field_config_for(col)
      name = col.name.to_sym
      type = col.type.to_sym
      type = :integer if type == :references

      fcs = dynamic_model.table_comments || {}
      # Comments will be in :original_fields if the config has been processed
      # for saving, or :fields if not
      fcs = fcs[:original_fields] || fcs[:fields] || {}
      comment = fcs[name]

      dmc = default_options.caption_before || {}
      caption = dmc.dig(name, :caption)

      lab = default_options.labels || {}
      label = lab[name]

      {
        type: type,
        label: label,
        caption: caption,
        comment: comment
      }
    end

    #
    # Datadic::Variable records need to be updated to match the new definition
    # if there have been changes, additions or deletions
    def refresh_variables_records
      form.fields.each do |_k, field|
        field.refresh_variable_record
      end
    end

    #
    # Refresh variable records (Datadic::Variable) based on
    # current definition.
    # @see Redcap::DataDictionaries::FieldDatadicVariables#refresh_variable_record
    def refresh_variable_record
      FieldDatadicVariable.new(self).refresh_variable_record
    end
  end
end
