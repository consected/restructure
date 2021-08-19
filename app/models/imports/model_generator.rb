# frozen_string_literal: true

module Imports
  #
  # Supports the analysis of CSV files to discern their structure, then
  # create DynamicModels from them, including the underlying database table
  # matching the retrieved data.
  class ModelGenerator < ActiveRecord::Base
    include AdminHandler
    include Dynamic::ModelGenerator

    self.table_name = 'imports_model_generators'

    belongs_to :admin

    after_initialize :setup

    before_validation :update_options
    before_validation :save_options

    validates :name, presence: true
    validates :dynamic_model_table, presence: true

    def self.default_category
      'import'
    end

    #
    # Class that implements options functionality
    def self.options_provider
      OptionConfigs::ImportModelGeneratorConfigs
    end

    def initialize(attrs = {})
      super
      setup
    end

    def setup
      setup_generator self, dynamic_model_table
      self.field_types = {}
      generator_config.setup_field_types_from_config field_types
    rescue StandardError => e
      Rails.logger.warn e
    end

    #
    # After setting up an Import instance, analyze the supplied CSV string
    # to guess the field types from the supplied data.
    # A hash of fieldname => type pairs is returned, with both key and value being symbols.
    # All rows are scanned and each field examined. If no type has been set yet, we set it using
    # the value's class.
    # If a type was :integer and we get a :float, we set the type to :float.
    # If a type was :float and we get an :integer, we keep the type as :float.
    # If a type has been set, but it doesn't match the current one, then we set :string
    # Any fields that were all nil will be set to :string
    # @param [String] csv - full CSV text
    # @return [Hash {fieldname: :type}]
    def analyze_csv(csv, keep_core_fields: nil)
      csv_rows = parse(csv)

      self.field_types = {}
      # Ensure the fields are set up in the original order
      csv_rows.headers.each do |name|
        field_types[name] = nil
      end

      csv_rows.each do |row|
        row.each do |name, field|
          next if field.nil?

          ftype = field.class.name.ns_underscore.to_sym
          ftype = :boolean if ftype == :string && field.in?(%w[true false])
          ftype = :datetime if ftype == :date_time

          curr_type = field_types[name]

          if curr_type.nil?
            field_types[name] = ftype
          elsif curr_type == :integer && ftype == :float || curr_type == :float && ftype == :integer
            field_types[name] = :float
          elsif curr_type != ftype
            field_types[name] = :string
          end
        end
      end

      unless keep_core_fields
        # Remove any of the core fields from the result
        self.class.core_field_names.each do |name|
          field_types.delete(name.to_sym)
        end
      end

      field_types.each_key do |k|
        field_types[k] ||= :string
      end

      field_types[:master_id] = :references if field_types.keys.include? :master_id

      generator_config.setup_fields_config field_types

      field_types
    end

    #
    # Parse the CSV string with appropriate converters and return a table
    # @param [String] csv
    # @return [CSV::Table]
    def parse(csv)
      CSV.parse(csv,
                headers: true,
                header_converters: :symbol,
                converters: %i[
                  integer
                  float
                  date
                  date_time
                ])
    end

    #
    # Create the model based on the current options configuration
    def create_dynamic_model
      res = super
      add_user_access_control
      res
    end

    def self.core_field_names
      %w[id user_id created_at updated_at disabled]
    end

    #
    # The latest database columns for the dynamic model.
    # Returns an array of connection.columns definitions.
    # Get name and type for each record with:
    #   record.name
    #   record.type
    # @return [Array]
    def dynamic_model_columns
      @dynamic_model_columns ||= dynamic_model.table_columns
    end

    #
    # Does the current dynamic model definition match the import fields configuration?
    # @return [Boolean | nil]
    def dynamic_model_def_current?
      # Check all columns are set
      return unless (dynamic_model_columns.map(&:name) - self.class.core_field_names).length == field_types.length

      # Check columns have the correct type
      res = true
      field_types.each do |k, v|
        v = :integer if v == :references
        unless dynamic_model_columns.find { |c| c.name == k.to_s }.type == v
          res = false
          break
        end
      end

      return res unless res

      # Check downcase is configured to match the dynamic model
      dynamic_model.default_options.field_options.each do |k, v|
        k = k.to_s
        unless config_fields.key?(k) && !!config_fields[k].no_downcase == !!v[:no_downcase]
          res = false
          break
        end
      end

      return res unless res

      # Check downcase is configured to match the dynamic model
      dmc = dynamic_model.default_options.caption_before
      config_fields.each do |k, v|
        k = k.to_sym
        text = Formatter::Substitution.text_to_html(v.caption)
        curr_text = dmc[k] && dmc[k][:caption]
        unless text == curr_text
          res = false
          break
        end
      end
      res
    end

    #
    # Set up or return the generator config class, for parsing the
    # text attribute #options.
    # Access configuration attributes directly as:
    #    generator_config[:<param name>].<name | type | default ...>
    # or
    #    generator_config.<param name>.<name | type | default ...>
    def generator_config
      @generator_config ||= OptionConfigs::ImportModelGeneratorConfigs.new(self)
    end

    #
    # Ensure the config options are saved back to the options field
    def save_options
      generator_config.save_options
    end

    #
    # Ensure the config options are updated if the configuration text has changed
    def update_options
      generator_config.update_options
    end

    #
    # All configured fields for the import generator
    def config_fields
      @config_fields ||= generator_config.fields
    end

    def fields
      config_fields
    end

    def disabled
      false
    end

    def disabled=(value)
      # ignore
    end

    #
    # Standard model method that states if a field should not be downcased when stored.
    # The dynamic model definition uses this to set up its configuration
    def no_downcase_field(name)
      config_fields[name].no_downcase
    end

    def add_user_access_control
      return unless admin.matching_user && dynamic_model
      return if admin.matching_user.has_access_to? :create, :table, dynamic_model.resource_name

      Admin::UserAccessControl.create!(app_type_id: admin.matching_user.app_type_id,
                                       resource_type: :table,
                                       resource_name: dynamic_model.resource_name,
                                       access: :create,
                                       disabled: false,
                                       current_admin: admin,
                                       user_id: admin.matching_user.id)
    end
  end
end
