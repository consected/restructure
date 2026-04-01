# frozen_string_literal: true

class SaveTriggers::FullTextSearch < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super
    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      model_def.each_value do |config|
        config = config.symbolize_keys if config.is_a?(Hash)

        with_entry_lifecycle(config) do
          next unless if_evaluates(config[:if])

          validate_config!(config)

          source_fields = config[:source_fields].map(&:to_sym)
          target_column = config[:target_column].to_s
          extra_content = config[:extra_content]
          ts_config = config[:ts_config] || 'english'

          text_content = ::FullTextSearch::TsvectorWriter.build_text_content(
            item: @item,
            with_fields: source_fields,
            extra_content: extra_content
          )

          if config[:target_table].present?
            write_to_separate_table(config, text_content, ts_config)
          else
            write_to_same_table(target_column, text_content, ts_config)
          end
        end
      end
    end
  end

  private

  def validate_config!(config)
    raise FphsException, 'full_text_search trigger requires source_fields' if config[:source_fields].blank?
    raise FphsException, 'full_text_search trigger requires target_column' if config[:target_column].blank?
  end

  def write_to_separate_table(config, text_content, ts_config)
    ::FullTextSearch::TsvectorWriter.write_tsvector(
      target_table: config[:target_table].to_s,
      target_field: config[:target_column].to_s,
      fk_column: config[:target_foreign_key_column].to_s,
      fk_value: @item.id,
      master_id: @item.respond_to?(:master_id) ? @item.master_id : nil,
      text_content: text_content,
      ts_config: ts_config
    )
  end

  def write_to_same_table(target_column, text_content, ts_config)
    ::FullTextSearch::TsvectorWriter.update_tsvector(
      table_name: @item.class.table_name,
      target_field: target_column,
      text_content: text_content,
      record_id: @item.id,
      ts_config: ts_config
    )
  end
end
