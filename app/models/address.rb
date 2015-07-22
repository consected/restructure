class Address < ActiveRecord::Base
  include UserHandler
  
  PrimaryRank = 10
  SecondaryRank = 5
  
  validates :zip, zip: true, allow_blank: true
  validates :source, source: true, allow_blank: true
  
  after_save :handle_primary_status


  protected
  
    def handle_primary_status
      
      if self.rank.to_i == PrimaryRank
        logger.info "Address rank set as primary in address #{self.id}. Setting other addresses for this master to secondary if they were primary."
        
        self.master.addresses.each do |a|
          if a.id != self.id && a.rank == PrimaryRank
            logger.info "Address #{a.id} has primary rank currently. Setting it to secondary"
            a.rank = 5
            a.save
            multiple_results << a
          end
        end
      end
      
    end
  
end
