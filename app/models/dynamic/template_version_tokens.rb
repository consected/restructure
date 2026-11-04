# frozen_string_literal: true

module Dynamic
  module TemplateVersionTokens
    def self.resource_token(definition)
      return 0 unless definition.respond_to?(:template_version_token)

      definition.template_version_token.to_i
    end

    def self.panel_chrome_token
      history_row_id_sum(Admin::PageLayout.table_name) + history_row_id_sum(Admin::AppConfiguration.table_name)
    end

    def self.activity_log_item_type_token(item_type)
      definitions = ActivityLog.where(item_type:)
      history_row_id_sum(ActivityLog.table_name, definitions:)
    end

    def self.live_config_library_tokens(definitions)
      unique_definitions = Array(definitions).compact.uniq do |definition|
        [definition.class.name, definition.id, definition.def_version, definition.updated_at]
      end
      tokens = unique_definitions.flat_map do |definition|
        next [] unless definition.respond_to?(:uses_current_definition_version?) &&
                       definition.uses_current_definition_version?

        OptionConfigs::ExtraOptions.requested_libraries(definition.options_text).map do |reference|
          library = Admin::ConfigLibrary.find_active_library!(
            reference[:category], reference[:name], format: 'yaml'
          )
          [reference[:category], reference[:name], library.id, library.updated_at.to_f]
        end
      end
      tokens.uniq.sort_by { |token| [token[0], token[1]] }
    end

    def self.history_row_id_sum(table_name, definitions: nil)
      connection = ActiveRecord::Base.connection
      history_table = connection.quote_table_name(Admin::MigrationGenerator.history_table_name_for(table_name))
      id_attribute = Admin::MigrationGenerator.history_table_id_attr_for(table_name)
      where_clause = if definitions
                       "WHERE #{connection.quote_column_name(id_attribute)} IN (#{definitions.select(:id).to_sql})"
                     else
                       ''
                     end

      connection.select_value("SELECT COALESCE(SUM(id), 0) FROM #{history_table} #{where_clause}").to_i
    end
  end
end
