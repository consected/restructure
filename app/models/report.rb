# frozen_string_literal: true

class Report < ActiveRecord::Base
  include AdminHandler
  include SelectorCache
  include OptionsHandler

  after_initialize :init_vars
  before_validation :downcase_item_type
  before_validation :check_attr_def
  before_validation :gen_short_name
  validates :report_type, presence: true
  validates :name, presence: true
  validate :valid_short_name?, unless: -> { disabled }
  validate :valid_item_type?, unless: -> { disabled }
  validate :valid_resource_name?, unless: -> { disabled }

  scope :counts, -> { where report_type: 'count' }
  scope :regular, -> { where report_type: 'regular_report' }
  scope :searchable, -> { where(searchable: true).order(position: :asc) }
  scope :editable_data_reports, -> { where("edit_model IS NOT NULL AND edit_model <> ''") }

  ReportTypes = %i[count regular_report search].freeze
  ReportIdAttribName = '_report_id_'

  configure :view_options, with: %i[hide_table_names humanize_column_names
                                    hide_result_count hide_export_buttons
                                    hide_criteria_panel prevent_collapse_for_list
                                    show_column_comments corresponding_data_dic
                                    view_as search_button_label report_auto_submit_on_change no_results_scroll]
  configure :list_options, with: %i[hide_in_list list_description]
  configure :view_css, with: %i[classes selectors]
  configure :component, with: [:options]
  configure :column_options, with: %i[tags classes hide show_as]

  attr_reader :clean_sql
  attr_reader :filtering_on
  attr_writer :current_user
  attr_reader :current_user
  attr_writer :search_attr_values

  attr_accessor :data_ref_table_name, :data_ref_schema_name, :data_ref_table_fields

  class BadSearchCriteria < FphsException
    def message
      'Bad search criteria were entered. Please check entries and try again.'
    end
  end

  # Class that implements options functionality
  def self.options_provider
    OptionConfigs::ReportOptions
  end

  # Attribute containing options to be parsed by the options provider
  def self.option_configs_attr
    :sql
  end

  # Get reports that the user has access to in its current app
  # @param [User] user
  # @return [ActiveRecord::Relation] reports
  def self.for_user(user)
    if user.has_access_to?(:read, :report, :_all_reports_)
      all
    else
      ns = []
      all.each do |r|
        ns << r.id if report_available_to_user r, user
      end

      where(id: ns)
    end
  end

  # Find a report based on an alt_resource_name style of "item_type__short_name" where a double underscore
  # acts as the divider between item_type "category" and short_name
  # @param csn [String] must match the pattern yyy__zzz
  # @return [Report] or raises an exception if not found
  def self.find_category_short_name(csn)
    parts = csn.split('__')
    raise FphsException, 'Bad item_type__short_name identifier' unless parts.length == 2

    i = parts.first
    # Allow hyphenated categories to be matched with underscores
    its = [i, i.gsub('_', '-')].uniq

    res = where(item_type: its, short_name: parts.last).first
    raise ActiveRecord::RecordNotFound unless res

    res
  end

  # Get the short name for a report based on the provided name
  # @param name [String] full name of the report
  # @return [String] short_name for the report
  def self.resource_name_for_named_report(name, item_type = nil)
    res = Report.active.where(name: name)

    res = res.where(item_type: item_type) if item_type

    res.order(updated_at: :desc).first&.alt_resource_name
  end

  def self.report_available_to_user(report, user)
    user.has_access_to?(:read, :report, report.alt_resource_name) || user.has_access_to?(:read, :report, report.name)
  end

  def can_access?(user)
    return true if self.class.report_available_to_user self, user

    user.has_access_to?(:read, :report, :_all_reports_)
  end

  # Generate a list of categories, which are the unique item_type values for active records
  def self.categories
    Report.active.select('distinct item_type').where('item_type is not null').all.map(&:item_type)
  end

  def self.item_types(refresh: false)
    Rails.cache.delete('Report.item_types') if refresh

    Rails.cache.fetch('Report.item_types') do
      res = []
      editable_data_reports.each do |r|
        unless r.selection_fields.blank?
          res += r.selection_fields.split(/[^a-zA-Z0-9_]/).collect { |c| "report_#{r.name.id_underscore}_#{c.downcase}".to_sym }
        end
      end
      res
    end
  end

  # Can the results be edited?
  def editable_data?
    !edit_model.blank?
  end

  # If the results can be edited, what class represents each result
  def edit_model_class
    return unless editable_data?

    model_class_name = edit_model.camelize.classify
    logger.info "Getting model class name: #{model_class_name}"
    if Report.const_defined?(model_class_name)
      Report.const_get(model_class_name)
    else
      obj_table_name = edit_model.downcase
      definition = self
      a_new_class = Class.new(ReportBase) do
        self.table_name = obj_table_name
        self.definition = definition
      end
      Report.const_set(model_class_name, a_new_class)
    end
  end

  # List all configured fields for editing, although not all of these fields may actually be updatable in reality
  def all_configured_edit_fields
    @all_configured_edit_fields ||= edit_field_names.split(/[^a-zA-Z0-9_]/).reject(&:blank?).collect(&:to_sym)
  end

  # Edit fields that can be updated in a record
  def edit_fields
    all_configured_edit_fields - search_reports_fields
  end

  # List any search_reports_ fields that represent criteria to feed to another report in the UI
  def search_reports_fields
    @search_reports_fields ||= all_configured_edit_fields.select { |s| s.to_s.start_with?('search_reports_') }
  end

  # Does the SQL definition specify a clause to filter a previous set of results?
  def filter_previous_clause?
    sql.include?(':filter_previous') || sql.include?(':ids_filter_previous')
  end

  def file_filtering_conditions(resource_name)
    NfsStore::Filter::Filter.generate_filters_for resource_name, user: current_user
  end

  def search_attr_values
    @search_attr_values || ''
  end

  def filtering_list
    logger.info "Reading filtering list for #{current_user}"
    return nil unless current_user

    key_list = "report-list: #{current_user.id}"
    Rails.cache.read(key_list)
  end

  def filtering_ids
    return nil unless current_user

    key = "report-results: #{current_user.id}"
    Rails.cache.read key
  end

  def write_filtering_list(list)
    logger.info "Writing filtering list for #{current_user}, #{list}"
    return nil unless current_user

    key_list = "report-list: #{current_user.id}"
    Rails.cache.write(key_list, list)
  end

  def write_filtering_ids(ids)
    logger.info "Writing filtering ids for #{current_user}, #{ids}"
    return nil unless current_user

    key = "report-results: #{current_user.id}"
    Rails.cache.write(key, ids)
  end

  def search_attributes
    @search_attrs = {} if search_attrs.blank?
    begin
      @search_attrs ||= JSON.parse search_attrs
    rescue StandardError
      @search_attrs ||= YAML.safe_load(search_attrs, [], [], true)
    end
  end

  def uses_table_subs?
    sql.include?('{{table_name}}') || sql.include?('{{table_fields}}')
  end

  def run(search_attr_values, options = {})
    @search_attr_values = search_attr_values
    @clean_sql = nil
    report_definition = self
    filtering_previous = false
    using_defaults = (@search_attr_values == '_use_defaults_')
    unless search_attrs_prep
      if options[:show_defaults_if_bad_attributes]
        using_defaults = (@search_attr_values == '_use_defaults_')
      else
        raise Report::BadSearchCriteria
      end
    end

    sql = report_definition.sql
    primary_table = 'masters'
    sql.strip!
    sql = sql[0..-2] if sql.last == ';'
    sql = sql.dup

    ids = filtering_ids
    @search_attr_values[:ids_filter_previous] = nil
    if current_user && options[:filter_previous] && !using_defaults

      logger.info "Trying to get data from cache (#{current_user.id} :#{ids}"
      if ids && sql.include?(':filter_previous')
        inner_sql = ' inner join (select id master_id from masters where id in (:filter_previous_ids)) filter_previous_alias using(master_id) '
        clean_inner_sql = ActiveRecord::Base.send(:sanitize_sql_for_conditions, [inner_sql, { filter_previous_ids: ids }])
        sql.gsub!(':filter_previous', clean_inner_sql) if clean_inner_sql

        filtering_previous = true
      end

      filtering_previous = true if sql.include?(':ids_filter_previous')
    end

    if filtering_previous
      @filtering_on = ids
      @search_attr_values[:ids_filter_previous] = @filtering_on
    end

    sql.gsub!(':filter_previous', '') if sql.include?(':filter_previous')

    self.data_ref_table_name = options[:table_name]
    self.data_ref_schema_name = options[:schema_name]
    self.data_ref_table_fields = options[:table_fields]
    if data_ref_table_name && data_ref_schema_name
      table_exists = Admin::MigrationGenerator.tables_and_views.find { |t| t['table_name'] == data_ref_table_name && t['schema_name'] == data_ref_schema_name }
      raise FphsException, 'invalid table name' unless table_exists

      raise FphsException, 'table fields incorrect' unless data_ref_table_fields == '*'

      sql = sql.gsub('{{table_name}}', data_ref_table_name)
      sql = sql.gsub('{{schema_name}}', data_ref_schema_name)
      sql = sql.gsub('{{table_fields}}', data_ref_table_fields)

    end

    sql.scan(/:current_user/) do |cu|
      sql = sql.sub(cu, current_user&.id.to_s || 'NULL')
    end

    sql.scan(/:file_filtering_conditions_for_[a-z_]+/) do |file_filter|
      if file_filter.present?
        resource_name = file_filter.sub(':file_filtering_conditions_for_', '')
        ffcond = file_filtering_conditions resource_name
        sql = sql.sub(file_filter, ffcond)
      end
    end

    # Import config libraries
    Admin::ConfigLibrary.make_substitutions! sql, :sql

    sql = "select count(*) \"result_count\" from (#{sql}) t".dup if options[:count_only]

    res = []

    logger.info "Preparing with #{@search_attr_values}"

    # get arbitrary data from a table
    # Perform this within a transaction to avoid unexpected data or or definition updates
    # Note that Postgres is really a requirement for a transaction to protect against DDL. Either way, limiting grants
    # on DDL to the Rails user is expected.
    self.class.connection.transaction do
      begin
        if @search_attr_values.respond_to? :to_unsafe_h
          @search_attr_values = @search_attr_values.to_unsafe_h.symbolize_keys
        end
        clean_sql = ActiveRecord::Base.send(:sanitize_sql_for_conditions, [sql, @search_attr_values])
      rescue StandardError => e
        logger.info "Unabled to sanitize sql: #{e.inspect}.\n#{e.backtrace.join("\n")}"
        raise Report::BadSearchCriteria
      end
      @clean_sql = clean_sql
      begin
        pg = self.class.connection
        # This is needed to get real return values for JSON
        @type_map ||= PG::BasicTypeMapForResults.new(pg.raw_connection)
        res = pg.execute(clean_sql)
        res.type_map = @type_map
      rescue StandardError => e
        logger.info "Unabled to run sql: #{e.inspect}.\n#{clean_sql}"
        raise FphsException, "Unabled to run sql: #{e.inspect}"
      end
      raise ActiveRecord::Rollback
    end

    @results = res

    # Store the results to the cache
    if current_user && !using_defaults
      begin
        m_field = field_index('master_id')
        ids = nil
        ids = res.map { |r| r[m_field] }.uniq! if m_field
        write_filtering_ids ids

        list = if filtering_previous
                 filtering_list || []
               else
                 []
               end

        l = nil
        if @search_attr_values
          l = @search_attr_values.dup
          l.delete(:ids_filter_previous)
          l.delete(:_report_id_)
          l.delete(:_filter_previous_)
          l.delete(:no_run)
          l.delete(:current_user)
        end
        list << { name: name, id: id, search_params: l, results_length: @results.count }

        write_filtering_list list
      rescue StandardError => e
        write_filtering_ids nil
        write_filtering_list nil
        logger.warn "Failed to write cache for #{current_user.id} => #{e.inspect}\n#{e.backtrace.join("\n")}"
      end
    end

    @results
  end

  # Get the table names corresponding to each column in the results
  # Since PG only returns oid values for each
  def result_tables
    return unless @results # && @results.count > 0

    return @result_tables if @result_tables

    @result_tables = {}
    logger.info 'Getting the array of result_tables'
    i = 0
    @results.fields.each do |_col|
      oid = @results.ftable(i).to_i.to_s # make sure it's clean and usable
      logger.info "OID: #{oid}"
      unless @result_tables.key? oid
        clean_sql = "select relname from pg_class where oid=#{oid.to_i}"
        get_res = self.class.connection.execute(clean_sql)

        table_name = get_res.first.first.last if get_res&.first

        @result_tables[oid] = table_name
      end
      i += 1
    end
    @result_tables
  end

  def result_tables_by_index
    return unless @results && @results.count > 0

    return @result_tables_oid if @result_tables_oid

    l = @results.fields.length

    logger.info "Setting up oids for tables in #{l} columns"

    @result_tables_oid = []
    (0..l - 1).each do |i|
      oid = @results.ftable(i).to_s
      logger.info "Getting oid: #{oid} for col #{i}"
      @result_tables_oid[i] = result_tables[oid]
    end
    @result_tables_oid
  end

  def use_defaults
    @search_attr_values = {}

    search_attributes.each do |k, v|
      @search_attr_values[k.to_sym] = FieldDefaults.calculate_default(self, v.first.last['default'], v.first.first)
    end
    logger.info "Using defaults as search attributes #{@search_attr_values}"
    @search_attr_values
  end

  def search_attrs_prep
    @search_attr_values = use_defaults if @search_attr_values == '_use_defaults_'

    all_blank = true

    search_attributes.each do |k, _v|
      search_attr_values[k.to_sym] = nil unless search_attr_values.key? k.to_sym
    end

    ks = search_attributes.keys.map(&:to_sym)

    search_attr_values.slice!(*ks)

    search_attr_values.symbolize_keys! if search_attr_values.respond_to? :symbolize_keys!

    search_attr_values.each do |k, v|
      all_blank &&= (k.to_s != ReportIdAttribName && (search_attributes[k.to_s].nil? || v.blank?))

      if v.blank?
        search_attr_values[k] = nil
      elsif v.is_a? Hash
        search_attr_values[k] = v.collect { |_, v1| v1 }
      elsif v.is_a?(String) && v.include?("\n")
        search_attr_values[k] = if search_attributes[k.to_s].first.last['multiple'] == 'multiple-regex'
                                  "(#{v.split("\n").map(&:squish).join('|')})"
                                else
                                  v.split("\n").map(&:squish)
                                end
      end
    end

    # We are now allowing blank searches, so don't return false for a blank search
    # return false if all_blank && search_attributes.length > 0

    true
  end

  def field_index(name)
    m_field = nil
    i = 0
    @results.fields.each do |f|
      if f == name
        m_field = i
        break
      end
      i += 1
    end

    m_field
  end

  def as_json(options = {})
    self.item_type = item_type.downcase if item_type
    self.short_name ||= gen_short_name
    super
  end

  def alt_resource_name
    "#{item_type&.id_underscore || '_default'}__#{short_name}".downcase.id_underscore
  end

  # Optionally show a different description in the list
  def list_description
    list_options.list_description || description
  end

  def gen_short_name
    self.short_name = name.downcase.id_underscore.gsub(/__+/, '_') if short_name.blank?
  end

  private

  def check_attr_def
    errmsg = []
    begin
      s = search_attributes
    rescue StandardError => e
      errmsg = e
    end

    unless s
      errors.add :search_attributes, "definition can not be parsed. Check the YAML or JSON is valid. #{errmsg.message}"
      # throw(:abort)
    end
  end

  def init_vars
    instance_var_init :results
    instance_var_init :result_tables
    instance_var_init :result_tables_oid
    instance_var_init :filtering_on
  end

  def downcase_item_type
    self.item_type = item_type.downcase if item_type
  end

  # Validate short_name is downcased
  def valid_short_name?
    short_name.id_underscore.downcase == short_name
  end

  # Validate the generated resource_name is not a duplicate
  def valid_resource_name?
    test = { short_name: short_name, item_type: item_type }

    res = self.class.active.where(test)
    unless (res.map(&:id) - [id]).empty?
      res.each do |res0|
        errors.add :resource_name, "is a duplicate of another report record: (#{name}) #{self} --duplicates-- (#{res0.name}) #{{ short_name: res0.short_name, item_type: res0.item_type }} "
      end
    end
  end

  # Validate the item_type to prevent multiple double underscores in resource_name
  def valid_item_type?
    return unless item_type

    parts = item_type.id_underscore.split('__')
    if parts.length > 1
      errors.add :item_type, "must not use multiple space or punctuation characters between letters: '#{item_type}' becomes #{item_type.id_underscore}"
    end
  end
end
