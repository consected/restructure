class PlayerContact < ActiveRecord::Base
  include UserHandler
  
  PrimaryRank = 10
  SecondaryRank = 5
  InactiveRank = 0
  
  
  validates :data, email: true, if: :is_email?
  validates :data, phone: true, if: :is_phone?
  validates :source, source: true, allow_blank: true
  validates :rank, presence: true
  after_save :handle_primary_status
  
  protected
    def is_email?
      rec_type == 'email'
    end
    def is_phone?
      rec_type == 'phone'
    end
    
    def handle_primary_status
      
      if self.rank.to_i == PrimaryRank
        logger.info "Player Contact rank set as primary in contact #{self.id} for type #{self.rec_type}. 
                    Setting other player contacts for this master to secondary if they were primary and have the type #{self.rec_type}."
        
        self.master.player_contacts.where(rank: PrimaryRank, rec_type: self.rec_type).each do |a|
          logger.info "Player Contact #{a.id} has primary rank currently. Current ID is #{self.id}"
          if a.id != self.id 
            logger.info "Player Contact #{a.id} has primary rank currently. Setting it to secondary"
            a.rank = 5
            a.save
            multiple_results << a
          end
        end
      end
      
    end
end
