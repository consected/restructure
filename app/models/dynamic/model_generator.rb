# frozen_string_literal: true

module Dynamic
  #
  # Supports the analysis of CSV files to discern their structure, then
  # create DynamicModels from them, including the underlying database table
  # matching the retrieved data.
  module ModelGenerator
    extend ActiveSupport::Concern

    included do
      # :field_types is a Hash of field_name => field_type values, where the field_name
      # is a symbol and field_type is a valid DB migration data type (also a symbol)
      attr_accessor :field_types, :array_fields, :prefix_config_library
      attr_accessor :parent, :qualified_table_name, :category
    end

    class_methods do
      def default_category
        'dynamic'
      end

      def default_schema_name
        'dynamic'
      end
    end

    #
    # Set up the key attributes for the generator. Typically called before
    # calling #create_dynamic_model or #dynamic_model
    # @param [Object] parent - parent object
    # @param [<Type>] qualified_table_name <description>
    # @return [<Type>] <description>
    def setup_generator(parent, qualified_table_name)
      # TODO: Verify possible conflict
      self.parent = parent
      self.qualified_table_name = qualified_table_name
      self.category ||= self.class.default_category
    end

    # Create an active dynamic model instance for storage of data records.
    # The table name can be qualified with a schema name, as <schema name>.<table name>
    # @return [DynamicModel]
    def create_dynamic_model
      raise FphsException, 'no fields specified to create dynamic model' unless field_list.present?

      schema_name, table_name = schema_and_table_name
      category = self.category || self.class.default_category

      default_options = {
        _comments: {
          table: table_comment_config,
          fields: comments
        },
        _data_dictionary: data_dictionary_config,
        _db_columns: db_columns,
        default: {
          field_options:,
          caption_before:,
          labels:,
          show_if_condition_strings:
        }
      }.deep_stringify_keys!

      options = YAML.dump default_options

      if prefix_config_library.present?
        options = options.sub(
          /^---/,
          "---\n#{prefix_config_library_string}\n"
        )
      end

      fla = field_list.split
      if fla.include?('master_id')
        foreign_key_name = 'master_id'
        @field_list = fla.select { |f| f != 'master_id' }.join(' ')
      end

      if dynamic_model
        @dynamic_model = dynamic_model
        puts "Updating dynamic model: #{table_name}"
        dynamic_model.update!(current_admin:,
                              field_list:,
                              options:,
                              allow_migrations: true,
                              foreign_key_name:)
        puts "Updated dynamic model: #{table_name}"
      else
        puts "Creating dynamic model: #{table_name}"
        @dynamic_model = DynamicModel.create!(current_admin:,
                                              name: dm_name,
                                              table_name:,
                                              primary_key_name: :id,
                                              foreign_key_name:,
                                              category:,
                                              field_list:,
                                              options:,
                                              schema_name:,
                                              allow_migrations: true)
      end

      # Force delayed job to update with the new definition
      AppControl.restart_delayed_job

      @dynamic_model
    end

    #
    # The dynamic model instance referenced by the table name in the instance attribute.
    # The table name can be qualified with a schema name, as <schema name>.<table name>
    # @param [true] no_check - don't check if the table is ready to use, otherwise return nil if it isn't
    # @return [DynamicModel]
    def dynamic_model(no_check: nil)
      return @dynamic_model if @dynamic_model

      schema_name, table_name = schema_and_table_name
      name = table_name.singularize

      schema_name = [nil, ''] if schema_name.blank?

      attrs = { table_name:, category:, schema_name: }
      dms = DynamicModel.active.where(attrs)

      if dms.length > 1
        Rails.logger.warn "Multiple dynamic models were found for #{attrs}\n" \
                          "The item with id #{dms.first.id} will be used"
      end

      @dynamic_model = dms.first
      return if !no_check && !dynamic_model_ready?

      @dynamic_model
    end

    #
    # Split the qualified table name into schema and table, if possible,
    # otherwise return with the default schema name
    # @return [<Type>] <description>
    def schema_and_table_name
      if qualified_table_name.include? '.'
        schema_name, table_name = qualified_table_name.split('.', 2)
      else
        table_name = qualified_table_name
        schema_name = self.class.default_schema_name
      end
      [schema_name, table_name]
    end

    #
    # Get the implementation class name for the dynamic model,
    # which is used for storage of records
    # @return [String]
    def dynamic_model_class_name
      dynamic_model.implementation_class.name
    end

    #
    # Check if the dynamic model for storage is ready to use,
    # both the DB table has been created and the class is defined
    # @return [true | nil]
    def dynamic_model_ready?
      return unless dynamic_model(no_check: true)
      return true if dynamic_model.implementation_class_defined?(Object, fail_without_exception: true)

      dynamic_model.generate_model if dynamic_model&.ready_to_generate?
      dynamic_model.implementation_class_defined?(Object, fail_without_exception: true)
    end

    #
    # String to form the library to prefix the options
    # @return [String]
    def prefix_config_library_string
      "# @library #{prefix_config_library}"
    end

    #
    # Check if the prefix config library has been added to the options
    # @return [true|false]
    def dynamic_model_config_library_added?
      !!dynamic_model&.options&.index(/^#{prefix_config_library_string}\w*\r?$/)
    end

    #
    # List of field names to be used in a dynamic model field list
    # @param [true|false] no_placeholder_fields - don't add placeholder fields into the list
    # @return [String]
    def field_list(no_placeholder_fields: false)
      return @field_list if @field_list

      fields = db_columns.keys.map(&:to_s)

      if respond_to?(:placeholder_fields) && !no_placeholder_fields
        placeholder_fields.each do |before, placeholder|
          i = fields.index(before)
          i ||= 0
          fields.insert(i, placeholder)
        end
      end

      @field_list = fields.join(' ')
    end

    private

    def current_admin
      return @current_admin if parent == self

      parent.current_admin
    end

    #
    # Return db_columns to summarize the real field types and enable definition
    # of a dynamic model
    # @return [Hash]
    def db_columns
      @db_columns = {}

      field_types.each do |field_name, field_type|
        ft = field_type.to_s
        config = {
          type: ft
        }

        config[:array] = true if array_fields&.dig(field_name)

        @db_columns[field_name] = config
      end

      @db_columns
    end

    #
    # Setup field_options config with no_downcase
    # @return [Hash]
    def field_options
      @field_options = {}

      field_types.each_key do |field_name|
        @field_options[field_name] = {
          no_downcase: no_downcase_field(field_name)
        }
      end

      @field_options
    end

    def caption_before
      @caption_before = {}
      return unless respond_to?(:fields) && fields

      fields.each do |name, config|
        html = config_value(config, :caption)
        next unless html

        html = Redcap::Utilities.html_to_markdown(html)
        @caption_before[name] = html
      end

      @caption_before
    end

    def labels
      @labels = {}
      return unless respond_to?(:fields) && fields

      fields.each do |name, config|
        html = config_value(config, :label)
        next unless html

        html = Redcap::Utilities.html_to_plain_text(html)
        @labels[name] = html
      end

      @labels
    end

    def comments
      @comments = {}
      return unless respond_to?(:fields) && fields

      fields.each do |name, config|
        next if name.to_s.index(/^embedded_report_|^placeholder_/)

        res = config_value(config, :comment)
        @comments[name] = res
      end

      @comments
    end

    def show_if_condition_strings
      @show_if_condition_strings = {}
      return unless respond_to?(:fields) && fields

      fields.each do |name, config|
        res = config_value(config, :show_if_condition_strings)
        @show_if_condition_strings[name] = res
      end

      @show_if_condition_strings
    end

    def data_dictionary_config
      super&.to_h if defined?(super)
    end

    def table_comment_config
      super if defined?(super)
    end

    def dm_name
      res = super if defined?(super)
      return res if res

      schema_name, table_name = schema_and_table_name
      table_name.singularize.humanize.titleize
    end

    def config_value(config, key)
      if config.is_a? String
        config
      elsif config.respond_to?(key)
        config.send(key)
      elsif config.key?(key)
        config[key]
      end
    end

    #
    # Should a field prevent downcasing - override in the implementing class
    # @param [String | Symbol] field_name
    # @return [Boolean]
    def no_downcase_field(_field_name)
      false
    end
  end
end
