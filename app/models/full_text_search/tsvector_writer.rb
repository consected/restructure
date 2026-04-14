# frozen_string_literal: true

module FullTextSearch
  #
  # Shared utility for writing tsvector data to PostgreSQL tables.
  # Used by SaveTriggers::FullTextSearch and NfsStore::Process::FullTextSearchJob.
  module TsvectorWriter
    VALID_IDENTIFIER = /\A[\w.]+\z/

    #
    # Write a tsvector value to a target table, performing an upsert
    # (insert or update on FK conflict).
    # @param target_table [String] fully qualified table name (e.g. 'schema.table')
    # @param target_field [String] tsvector column name
    # @param text_content [String] text to convert to tsvector
    # @param fk_column [String] foreign key column name for upsert conflict
    # @param fk_value [Integer] foreign key value
    # @param master_id [Integer, nil] optional master_id
    # @param ts_config [String] PostgreSQL text search configuration (default: 'english')
    def self.write_tsvector(target_table:, target_field:, text_content:, fk_column:, fk_value:, master_id: nil,
                            ts_config: 'english')
      validate_identifier!(target_table, 'target_table')
      validate_identifier!(target_field, 'target_field')
      validate_identifier!(fk_column, 'fk_column')

      conn = ActiveRecord::Base.connection
      quoted_table = target_table.split('.').map { |p| conn.quote_column_name(p) }.join('.')
      quoted_field = conn.quote_column_name(target_field)
      quoted_fk = conn.quote_column_name(fk_column)

      sql = <<~SQL
        INSERT INTO #{quoted_table} (#{quoted_fk}, master_id, #{quoted_field}, created_at, updated_at)
        VALUES ($1, $2, to_tsvector($4, $3), now(), now())
        ON CONFLICT (#{quoted_fk})
        DO UPDATE SET #{quoted_field} = to_tsvector($4, $3), updated_at = now()
      SQL

      binds = [
        bind_param('fk_value', fk_value, ActiveModel::Type::Integer.new),
        bind_param('master_id', master_id, ActiveModel::Type::Integer.new),
        bind_param('text_content', text_content.to_s, ActiveModel::Type::String.new),
        bind_param('ts_config', ts_config.to_s, ActiveModel::Type::String.new)
      ]

      conn.exec_query(sql, 'FullTextSearch::TsvectorWriter', binds)
    end

    #
    # Update a tsvector column on an existing record's own table.
    # @param table_name [String] fully qualified table name (e.g. 'schema.table')
    # @param target_field [String] tsvector column name
    # @param text_content [String] text to convert to tsvector
    # @param record_id [Integer] id of the row to update
    # @param ts_config [String] PostgreSQL text search configuration (default: 'english')
    def self.update_tsvector(table_name:, target_field:, text_content:, record_id:, ts_config: 'english')
      validate_identifier!(table_name, 'table_name')
      validate_identifier!(target_field, 'target_field')

      conn = ActiveRecord::Base.connection
      quoted_table = table_name.split('.').map { |p| conn.quote_column_name(p) }.join('.')
      quoted_field = conn.quote_column_name(target_field)

      sql = <<~SQL
        UPDATE #{quoted_table}
        SET #{quoted_field} = to_tsvector($1, $2)
        WHERE id = $3
      SQL

      binds = [
        bind_param('ts_config', ts_config.to_s, ActiveModel::Type::String.new),
        bind_param('text_content', text_content.to_s, ActiveModel::Type::String.new),
        bind_param('record_id', record_id, ActiveModel::Type::Integer.new)
      ]

      conn.exec_query(sql, 'FullTextSearch::TsvectorWriter', binds)
    end

    #
    # Build text content by concatenating field values from an item.
    # @param item [ActiveRecord::Base] record with field values
    # @param with_fields [Array<Symbol>] field names to extract
    # @param extra_content [String, nil] additional text to append
    # @return [String] concatenated text
    def self.build_text_content(item:, with_fields:, extra_content: nil)
      parts = with_fields.filter_map do |field|
        val = item.send(field).to_s
        val.presence
      end

      parts << extra_content if extra_content.present?
      parts.join(' ')
    end

    def self.validate_identifier!(value, name)
      raise ArgumentError, "Invalid #{name}: #{value.inspect}" unless value.to_s.match?(VALID_IDENTIFIER)
    end
    private_class_method :validate_identifier!

    def self.bind_param(name, value, type)
      ActiveRecord::Relation::QueryAttribute.new(name, value, type)
    end
    private_class_method :bind_param
  end
end
