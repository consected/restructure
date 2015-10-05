class Report < ActiveRecord::Base
  
  include AdminHandler
  include SelectorCache

  validates :name, presence: true
#  
#  {
#      primary_table: 'tracker_history',
#      sql: "select count(*) from tracker_history where event_date >= :from_event_date and event_date <= :to_event_date; ",
#      search_attrs: {
#        from_event_date: :date,
#        to_event_date: :date
#      }      
#    }
  
  
  
  def self.run report_id, search_attrs
    
    
    
    report_definition = Report.find report_id.to_i

    sql = report_definition[:sql]
    primary_table = report_definition[:primary_table]
    
    
    
    res=[]
    
    # get arbitrary data from a table
    # Perform this within a transaction to avoid unexpected data or or definition updates
    # Note that Postgres is really a requirement for a transaction to protect against DDL. Either way, limiting grants 
    # on DDL to the Rails user is expected.
    connection.transaction do
      res = connection.execute(ActiveRecord::Base.send(:sanitize_sql, [sql, search_attrs], primary_table))    
      raise ActiveRecord::Rollback
    end
    
    res
    
  end
  
end
