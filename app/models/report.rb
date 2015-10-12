class Report < ActiveRecord::Base
  
  include AdminHandler
  include SelectorCache
    
  scope :enabled, -> {where "disabled <> true"}  
  
  class BadSearchCriteria < Exception
    
  end
  
  validates :name, presence: true

  def search_attr_values
    @search_attr_values || ''
  end
  
  def search_attributes
    begin
      @search_attrs ||= JSON.parse self.search_attrs
    rescue
      @search_attrs ||= YAML.load self.search_attrs
    end
      
  end
  
  
  def run  search_attr_values
    
    @search_attr_values = search_attr_values
    
    report_definition = self

    sql = report_definition.sql
    primary_table = 'masters'
    
    raise Report::BadSearchCriteria unless search_attrs_ok
    
    res=[]
    
    # get arbitrary data from a table
    # Perform this within a transaction to avoid unexpected data or or definition updates
    # Note that Postgres is really a requirement for a transaction to protect against DDL. Either way, limiting grants 
    # on DDL to the Rails user is expected.
    self.class.connection.transaction do
      clean_sql = ActiveRecord::Base.send(:sanitize_sql, [sql, @search_attr_values], primary_table)
      logger.info "CLEAN SQL:: #{clean_sql}"
      res = self.class.connection.execute(clean_sql)    
      raise ActiveRecord::Rollback
    end
    
    @results = res
        
  end
  
  
  # Get the table names corresponding to each column in the results
  # Since PG only returns oid values for each
  def result_tables
            
    return unless @results && @results.count > 0
    
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
  
  def search_attrs_ok 
    
    search_attr_values.each do |k,v|
      if search_attributes[k.to_s].nil? || v.blank?
        return false
      end
    end
    true
  end
  
  
end
