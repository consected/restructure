class Report < ActiveRecord::Base
  
  include AdminHandler
  include SelectorCache
  
  before_validation :check_attr_def
  validates :report_type, presence: true
  validates :name, presence: true  
  
  default_scope -> {order auto: :desc, report_type: :asc, position: :asc }
  
  scope :counts, -> {where report_type: 'count'}
  scope :regular, -> {where report_type: 'regular_report'}
  scope :searchable, -> {where searchable: true}
  
  ReportTypes = [:count, :regular_report, :search]
  ReportIdAttribName = '_report_id_'
    
  class BadSearchCriteria < FphsException
    def message 
      "Bad search criteria were entered. Please check entries and try again."
    end
  end
  
  
  def report_identifier
    name.id_underscore
  end
  
  def clean_sql
    @clean_sql
  end
  
  def search_attr_values
    @search_attr_values || ''
  end
  
  def search_attributes
    @search_attrs = {} if self.search_attrs.blank?  
    begin
      @search_attrs ||= JSON.parse self.search_attrs
    rescue
      @search_attrs ||= YAML.load self.search_attrs
    end
    
  end
  
  
  def run  search_attr_values
    
    @search_attr_values = search_attr_values    
    @clean_sql = nil
    report_definition = self

    sql = report_definition.sql
    primary_table = 'masters'
    
    raise Report::BadSearchCriteria unless search_attrs_prep
    
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
      
      @search_attr_values[k.to_sym] = self.class.calculate_default v.first.last['default'], v.first.first
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
    
    
    search_attr_values.each do |k,v|
      all_blank &&= (k.to_s != ReportIdAttribName && (search_attributes[k.to_s].nil? || v.blank?))
    
      if v.blank?
        search_attr_values[k] = nil
      elsif v.is_a? Hash
        search_attr_values[k] = v.collect{|k,v| v}
      elsif v.is_a?(String) && v.include?("\n")
        search_attr_values[k] = v.split("\n").map{|a| a.squish}
      end
    end
    
    
    
    return false if all_blank && search_attributes.length > 0
      
    true
  end
  

  def self.calculate_default default, type
    default ||= ''
    
    res = default
    if default.is_a? String
      m = default.scan /(-\d+) (days|day|months|month|years|year)/
      if m.first
        t = m.first.last      
        res = DateTime.now + m.first.first.to_i.send(t)
      elsif default == 'now'  
        res = DateTime.now
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

end
