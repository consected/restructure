class Address < ActiveRecord::Base
  include UserHandler
  
  PrimaryRank = 10
  SecondaryRank = 5
  InactiveRank = 0
  
  validates :zip, zip: true, allow_blank: true
  validates :source, source: true, allow_blank: true
  validates :rank, presence: true
  
  before_save :handle_country
  after_save :handle_primary_status
  
#  def rank_name
#    return unless rank
#    self.class.get_rank_name rank
#  end    
  
  
  protected
  
    def handle_primary_status
      
      if self.rank.to_i == PrimaryRank
        logger.info "Address rank set as primary in address #{self.id}. Setting other addresses for this master to secondary if they were primary."
        
        self.master.addresses.where(rank: PrimaryRank).each do |a|
          if a.id != self.id
            logger.info "Address #{a.id} has primary rank currently. Setting it to secondary"
            a.rank = 5
            a.save
            multiple_results << a
          end
        end
      end
      
    end
    
    def handle_country
      if country
        self.country = country.downcase        

        if country.downcase == 'us'
          self.region = nil
          self.postal_code = nil
          return true
        else
          if region.blank? && postal_code.blank?
            self.errors.add :country, "was not USA and province/county and postal code are blank. At least one must be entered for countries other than USA."
            return false
          else
            self.state = nil
            self.zip = nil
            
            return true
          end
        end
        
      else
        true
      end  
    end
  
end
