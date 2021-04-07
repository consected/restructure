# frozen_string_literal: true

module Imports
  #
  # Supports the analysis of CSV files to discern their structure, then
  # create DynamicModels from them, including the underlying database table
  # matching the retrieved data.
  class ModelGenerator < ActiveRecord::Base
    include AdminHandler
    include Dynamic::ModelGenerator

    DefaultCategory = 'import'
    self.table_name = 'imports_model_generators'

    belongs_to :admin

    after_initialize -> { setup_generator(import, dynamic_model_table) }

    before_validation :save_options
    validates :name, presence: true
    validates :dynamic_model_table, presence: true

    attr_accessor :import

    #
    # Class that implements options functionality
    def self.options_provider
      OptionConfigs::ImportModelGeneratorConfigs
    end

    def initialize(attrs = {})
      super
      setup_generator self, dynamic_model_table
      self.field_types = {}
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

    def self.core_field_names
      %w[id user_id created_at updated_at disabled]
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

    def disabled
      false
    end

    def disabled=(value)
      # ignore
    end
  end
end
