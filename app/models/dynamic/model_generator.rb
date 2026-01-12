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
      attr_accessor :field_types, :array_fields, :prefix_config_library,
                    :associate_master_through_external_id_resource_name,
                    :associate_master_through_external_id_fkey_name,
                    :include_all_fields_in_option_types, :foreign_key_name,
                    :option_type_attr_name
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

      default_options = generate_default_options
      merge_option_types!(default_options)

      default_options.deep_stringify_keys!
      options = String.yaml_dump(default_options)
      options = "#{prefix_config_library_string}\n\n#{options}" if prefix_config_library.present?

      set_up_foreign_key

      if dynamic_model
        puts "Updating dynamic model: #{table_name} in schema #{dynamic_model.schema_name}"
        dynamic_model.update!(current_admin:,
                              field_list:,
                              options:,
                              allow_migrations: true,
                              foreign_key_name:)
        puts "Updated dynamic model: #{table_name} in schema #{dynamic_model.schema_name}"
      else
        puts "Creating dynamic model: #{table_name} in #{schema_name}"
        @dynamic_model = DynamicModel.create!(current_admin:,
                                              name: dynamic_model_name,
                                              table_name:,
                                              primary_key_name: :id,
                                              foreign_key_name:,
                                              category:,
                                              field_list:,
                                              options:,
                                              schema_name:,
                                              allow_migrations: true)
        puts "Created dynamic model: #{table_name} in #{schema_name}"
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
    def dynamic_model(no_check: nil, force: nil)
      return @dynamic_model if @dynamic_model && !force

      schema_name, table_name = schema_and_table_name
      table_name.singularize

      schema_name = [nil, ''] if schema_name.blank?

      attrs = { table_name:, schema_name: }
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
    # String to form the _configurations.foreign_key_through_external_id option
    # @return [String]
    def associate_master_through_external_id_string
      "  foreign_key_through_external_id: #{associate_master_through_external_id_resource_name}"
    end

    #
    # Check if the _configurations.foreign_key_through_external_id setting has been added to the options
    # @return [true|false]
    def dynamic_model_master_external_id_added?
      !!dynamic_model&.options&.index(/^#{associate_master_through_external_id_string}\w*\r?$/)
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

    #
    # Returns an array of all dynamic model field names (symbols by default),
    # the fields that will appear in the dynamic model definition
    # @params[Symbol] return_as :symbols (default) or :strings
    # @return [Array]
    def all_dynamic_model_field_names(return_as = :symbols)
      return fields.stringify_keys.keys if return_as == :strings

      fields.symbolize_keys.keys
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
        next unless html.present?

        html = Redcap::Utilities.html_to_markdown(html)
        next unless html.present?

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

    def dynamic_model_name
      res = super if defined?(super)
      return res if res

      _, table_name = schema_and_table_name
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

    def generate_default_options
      def_configs = {}
      if associate_master_through_external_id_resource_name.present?
        def_configs[:foreign_key_through_external_id] = associate_master_through_external_id_resource_name
      end

      def_configs[:option_type_attr_name] = option_type_attr_name if option_type_attr_name.present?

      default_options = {}
      if dynamic_model
        # Load the existing option configurations if the dynamic model exists
        dynamic_model.option_configs(force: true)
        # Set up the _configurations based on the dynamic model's existing configurations
        # removing any that are already in def_configs to avoid duplication
        existing = dynamic_model.configurations&.reject { |k, _v| def_configs.key?(k) }
        default_options[:_configurations] = existing
      end

      default_options.merge!(
        {
          _configurations_from_model_generator: def_configs,
          _comments: {
            table: table_comment_config,
            fields: comments
          },
          _data_dictionary: data_dictionary_config,
          _db_columns: db_columns,
          _default_from_model_generator: {
            field_options:,
            caption_before:,
            labels:,
            show_if_condition_strings:
          },
          default: {
            fields: all_dynamic_model_field_names(:strings)
          }
        }
      )
    end

    #
    # If the target dynamic model is intended to have option types
    # handle the creation of the options for each of them and merge
    # them into the default options.
    # The result depends on whether `include_all_fields_in_option_types` is set to
    # `:hide_external_fields` or not.
    # If we need access to all fields in all the option
    # types, and then hide the "external" fields, we include all the fields in the
    # `fields` list for all the option types, then set the `field_options` to hide the
    # "external" fields.
    # If not, we just include the fields that belong to each option type. This means they
    # aren't accessible when that option type is selected, so are implied to be hidden and
    # not returned for use in the front end or API calls.
    # @param [Hash] default_options
    def merge_option_types!(default_options)
      return unless respond_to?(:option_types) && option_types

      all_field_names = all_dynamic_model_field_names(:symbols)
      option_types.each do |name|
        fields_for_ot = field_names_by_option_type[name.to_sym]

        if include_all_fields_in_option_types == :hide_external_fields
          # All fields will be included
          ot_fields = all_field_names.dup
          ot_field_options = {}
          external_fields = all_field_names - fields_for_ot
          all_field_names.each do |fn|
            if external_fields.include?(fn)
              if fn.to_s.index(/(placeholder_|embedded_report_)/)
                # For external fields that are not "real", remove them from the list
                # since there is no field value to actually retrieve
                ot_fields.delete_if { |v| v == fn }
                next
              end

              # Set the field to be hidden
              # and maintain the other field options if they exist
              ot_field_options[fn] = (field_options[fn] || {}).deep_dup.merge(
                edit_as: {
                  field_type: "hidden_#{fn}"
                }
              )
            elsif field_options[fn]
              # Use the normal field options
              ot_field_options[fn] = field_options[fn].deep_dup
            end
          end
        else
          # The field options are not needed since the field won't be hidden
          ot_field_options = nil
          # Only the fields for this option type will be included
          ot_fields = fields_for_ot
        end

        ot_def = { name => { fields: ot_fields } }
        ot_def[name][:field_options] = ot_field_options if ot_field_options
        # Merge the option type definition into the default options
        default_options.merge!(ot_def)
      end
    end

    #
    # Handle setting the `foreign_key_name` based on configurations or the
    # existence of `master_id` in the `field_list` if already set
    # @return [String] field list
    def set_up_foreign_key
      if associate_master_through_external_id_fkey_name.present?
        self.foreign_key_name = associate_master_through_external_id_fkey_name
      end

      # Remove master_id from the list and make it the foreign key name, only if
      # the foreign_key_name was not already set or was set to master_id already
      fla = field_list.split
      return unless fla.include?('master_id') && (foreign_key_name.blank? || foreign_key_name == 'master_id')

      self.foreign_key_name = 'master_id'
      @field_list = fla.reject { |f| f == 'master_id' }.join(' ')
    end
  end
end
