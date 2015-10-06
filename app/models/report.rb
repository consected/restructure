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
    @search_attrs ||= JSON.parse self.search_attrs
  end
  
  
  def run  search_attr_values
    
    @search_attr_values = search_attr_values
    
    report_definition = self

    sql = report_definition.sql
    primary_table = report_definition.primary_table
    
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
    
    res
    
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
