class Report < ActiveRecord::Base

  include AdminHandler
  include SelectorCache

  after_initialize :init_vars
  before_validation :check_attr_def
  validates :report_type, presence: true
  validates :name, presence: true



  scope :counts, -> {where report_type: 'count'}
  scope :regular, -> {where report_type: 'regular_report'}
  scope :searchable, -> {where(searchable: true).order(position: :asc)}

  scope :editable_data_reports, -> {where("edit_model IS NOT NULL AND edit_model <> ''") }

  ReportTypes = [:count, :regular_report, :search]
  ReportIdAttribName = '_report_id_'

  class BadSearchCriteria < FphsException
    def message
      "Bad search criteria were entered. Please check entries and try again."
    end
  end

  def self.for_user user

    if user.has_access_to?(:read, :report, :_all_reports_)
      all
    else
      ns = []
      all.each do |r|
        ns << r.id if user.has_access_to? :read, :report, r.name
      end

      where(id: ns)
    end
  end

  def can_access? user
    return true if user.has_access_to?(:read, :report, self.name)
    return user.has_access_to?(:read, :report, :_all_reports_)
  end

  def self.categories
    Report.select("distinct item_type").where('item_type is not null').all.map {|s| s.item_type}
  end

  def self.item_types
    res = []
    editable_data_reports.each do |r|

      unless r.selection_fields.blank?
        res += r.selection_fields.split(/[^a-zA-Z0-9_]/).collect {|c| "report_#{r.name.id_underscore}_#{c.downcase}".to_sym}
      end
    end
    res
  end


  def editable_data?
    !edit_model.blank?
  end

  def edit_model_class
    return unless editable_data?
    model_class_name = edit_model.camelize.classify
    logger.info "Getting model class name: #{model_class_name}"
    if Report.const_defined?(model_class_name)
      Report.const_get(model_class_name)
    else
      obj_table_name = edit_model.downcase
      a_new_class = Class.new(ReportBase) do
        self.table_name = obj_table_name
      end
      Report.const_set(model_class_name, a_new_class)
    end
  end

  def search_reports_fields
    @search_reports_fields ||= all_edit_fields.select {|s| s.to_s.start_with?('search_reports_') }
  end

  def all_edit_fields
    @all_edit_fields ||= edit_field_names.split(/[^a-zA-Z0-9_]/).select {|s| !s.blank?}.collect {|s| s.to_sym}
  end

  def edit_fields
    all_edit_fields - search_reports_fields
  end

  def report_identifier
    name.id_underscore
  end

  def clean_sql
    @clean_sql
  end

  def filtering_on
    @filtering_on
  end

  def filter_previous_clause?
    sql.include?(':filter_previous') || sql.include?(':ids_filter_previous')
  end

  def current_user= cu
    @current_user = cu
  end

  def current_user
    @current_user
  end

  def search_attr_values
    @search_attr_values || ''
  end

  def search_attr_values= sav
    @search_attr_values = sav
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

  def write_filtering_list list
    logger.info "Writing filtering list for #{current_user}, #{list}"
    return nil unless current_user
    key_list = "report-list: #{current_user.id}"
    Rails.cache.write(key_list, list)
  end

  def write_filtering_ids ids
    logger.info "Writing filtering ids for #{current_user}, #{ids}"
    return nil unless current_user
    key = "report-results: #{current_user.id}"
    Rails.cache.write(key, ids)
  end

  def search_attributes
    @search_attrs = {} if self.search_attrs.blank?
    begin
      @search_attrs ||= JSON.parse self.search_attrs
    rescue
      @search_attrs ||= YAML.load self.search_attrs
    end

  end


  def run  search_attr_values, options={}

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

    ids = filtering_ids
    @search_attr_values[:ids_filter_previous] = nil
    if current_user && options[:filter_previous] && !using_defaults

      logger.info "Trying to get data from cache (#{current_user.id} :#{ids}"
      if ids && sql.include?(":filter_previous")
        inner_sql = " inner join (select id master_id from masters where id in (:filter_previous_ids)) filter_previous_alias using(master_id) "
        clean_inner_sql = ActiveRecord::Base.send(:sanitize_sql, [inner_sql, {filter_previous_ids: ids}], primary_table)
        sql.gsub!(":filter_previous", clean_inner_sql) if clean_inner_sql

        filtering_previous = true
      end

      filtering_previous = true if sql.include?(':ids_filter_previous')
    end

    if filtering_previous
      @filtering_on = ids
      @search_attr_values[:ids_filter_previous] = @filtering_on
    end


    if sql.include?(":filter_previous")
      sql.gsub!(":filter_previous", '')
    end

    if options[:count_only]
      sql = "select count(*) \"result_count\" from (#{sql}) t"
    end

    res=[]

    logger.info "Preparing with #{@search_attr_values}"

    # get arbitrary data from a table
    # Perform this within a transaction to avoid unexpected data or or definition updates
    # Note that Postgres is really a requirement for a transaction to protect against DDL. Either way, limiting grants
    # on DDL to the Rails user is expected.
    self.class.connection.transaction do
      begin
        clean_sql = ActiveRecord::Base.send(:sanitize_sql, [sql, @search_attr_values], primary_table)
      rescue => e
        logger.info "Unabled to sanitize sql: #{e.inspect}.\n#{e.backtrace.join("\n")}"
        raise Report::BadSearchCriteria
      end
      @clean_sql = clean_sql
      res = self.class.connection.execute(clean_sql)
      raise ActiveRecord::Rollback
    end

    @results = res

    # Store the results to the cache
    if current_user && !using_defaults
      begin
        m_field = field_index('master_id')
        ids = nil
        if m_field
          ids = []
          res.each_row {|r| ids << r[m_field]}
        end
        write_filtering_ids ids

        if filtering_previous
          list = filtering_list || []
        else
          list = []
        end

        l = nil
        if @search_attr_values
          l = @search_attr_values.dup
          l.delete(:ids_filter_previous)
          l.delete(:_report_id_)
          l.delete(:_filter_previous_)
          l.delete(:no_run)
        end
        list << {name: name, id: id, search_params: l, results_length: @results.count}



        write_filtering_list list



      rescue =>e
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

    return unless @results #&& @results.count > 0

    return @result_tables if @result_tables

    @result_tables = {}
    logger.info "Getting the array of result_tables"
    i = 0
    @results.fields.each do |col|
      oid = @results.ftable(i).to_i.to_s #make sure it's clean and usable
      logger.info "OID: #{oid}"
      unless @result_tables.has_key? oid
        clean_sql = "select relname from pg_class where oid=#{oid.to_i}"
        get_res = self.class.connection.execute(clean_sql)

        table_name = get_res.first.first.last if get_res && get_res.first

        @result_tables[oid] = table_name
      end
      i+=1
    end
    @result_tables
  end

  def result_tables_by_index

    return unless @results && @results.count > 0

    return @result_tables_oid if @result_tables_oid

    l = @results.fields.length

    logger.info "Setting up oids for tables in #{l} columns"

    @result_tables_oid = []
    (0..l-1).each do |i|
      oid = @results.ftable(i).to_s
      logger.info "Getting oid: #{oid} for col #{i}"
      @result_tables_oid[i] = result_tables[oid]
    end
    @result_tables_oid
  end

  def use_defaults
    @search_attr_values = {}

    search_attributes.each do |k,v|

      @search_attr_values[k.to_sym] = self.calculate_default v.first.last['default'], v.first.first
    end
    logger.info "Using defaults as search attributes #{@search_attr_values}"
    @search_attr_values
  end

  def search_attrs_prep


    @search_attr_values = use_defaults if @search_attr_values == '_use_defaults_'

    all_blank = true

    search_attributes.each do |k,v|
      search_attr_values[k.to_sym] = nil unless search_attr_values.has_key? k.to_sym
    end

    ks = search_attributes.keys
    search_attr_values.slice!(*ks)

    search_attr_values.symbolize_keys! unless search_attr_values.is_a?(ActionController::Parameters)

    search_attr_values.each do |k,v|
      all_blank &&= (k.to_s != ReportIdAttribName && (search_attributes[k.to_s].nil? || v.blank?))

      if v.blank?
        search_attr_values[k] = nil
      elsif v.is_a? Hash
        search_attr_values[k] = v.collect{|_,v1| v1}
      elsif v.is_a?(String) && v.include?("\n")
        if search_attributes[k.to_s].first.last['multiple'] == 'multiple-regex'
          search_attr_values[k] = "(#{v.split("\n").map{|a| a.squish}.join('|')})"
        else
          search_attr_values[k] = v.split("\n").map{|a| a.squish}
        end
      end
    end


    # We are now allowing blank searches, so don't return false for a blank search
    # return false if all_blank && search_attributes.length > 0

    true
  end


  def calculate_default default, type
    default ||= ''

    res = default
    if default.is_a? String
      m = default.scan(/(-\d+) (days|day|months|month|years|year)/)
      if m.first
        t = m.first.last
        res = DateTime.now + m.first.first.to_i.send(t)
      elsif default == 'now'
        res = DateTime.now
      elsif default == 'current_user'
        res = self.current_user.id
      end
    end

    if type == 'date'
      res = res.strftime('%Y-%m-%d') rescue nil
    end

    res
  end

  def field_index name
    m_field = nil
    i = 0
    @results.fields.each do |f|
      if f == name
        m_field = i
        break
      end
      i+=1
    end

    return m_field
  end


  def check_attr_def
    errmsg = []
    begin
      s = search_attributes
    rescue => e
      errmsg = e
    end
    errors.add :search_attributes, "definition can not be parsed. Check the YAML or JSON is valid. #{errmsg.message}" unless s
  end


  def init_vars
    instance_var_init :results
    instance_var_init :result_tables
    instance_var_init :result_tables_oid
    instance_var_init :filtering_on
  end
end
