class SageAssignment < ActiveRecord::Base
  include UserHandler
  include ExternalIdHandler

  validates :sage_id, presence: true,  length: {is: 10}
  validate :sage_id_tests    
  default_scope -> {order id: :desc}
  after_save :return_all
 
  
  def return_all
    self.multiple_results = self.master.sage_assignments.all if self.master
  end
  
  
  def self.generate_ids admin, count=10
    
    raise "Only admins can perform this function" unless admin && admin.enabled?
    
    res = []
    
    (1..count).each do |c|      
      
      begin
        #s = SecureRandom.random_number(8_999_999_999) + 1_000_000_000        
        item = SageAssignment.new(sage_id: generate_random_id.to_s, admin_id: admin.id)
        item.no_track = true      
        item.save!
        res << item
      rescue PG::UniqueViolation => e
        logger.info "Failed to create a Sage Assignment record due to an random duplicate"
      end  
      
    end
    
    res
  end
  

  
  def check_status
    @was_created = id_changed? || just_assigned ? 'created' : false
    @was_updated = updated_at_changed? ? 'updated' : false
  end
  
  protected
  
  
    def sage_id_tests
      
      if persisted? && sage_id_changed? 
        errors.add :sage_id, "can not be changed" 
      end
      
      if persisted? && master_id_changed? && !master_id_was.nil?
        errors.add :master, "record this sage ID is associated with can not be changed" 
      end
      
    end
    
    def creatable_without_user
      true
    end
    
  end
  
