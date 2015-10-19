class SageAssignment < ActiveRecord::Base
  include UserHandler

  validates :sage_ext_id, presence: true,  numericality: { only_integer: true, greater_than: 0, less_than: 10000000000 }
  validate :sage_ext_id_tests    
  default_scope ->{}
  
  # We assign the next available 
  def self.assign_next_available_id #master_id, current_user
        
    # Use a transaction to ensure locking / atomicity of the request
    self.transaction do
      sage_assignment = self.next_available
      sage_assignment.assigned_by = "fphsapp"
      #sage_assignment.user = current_user
      #sage_assignment.master_id = master_id
      sage_assignment.save!

      sage_assignment.reload            
    end    
  end
  
  def self.next_available
    SageAssignment.select("min(id) id, sage_ext_id").where("master_id is null").group("sage_ext_id").first
  end
  
  protected
  
  
    def sage_ext_id_tests
      
      if sage_ext_id_changed? 
        errors.add :sage_ext_id, "can not be changed" 
      end
      
      if master_id_changed? && master_id?
        errors.add :master, "record this sage ID is associated with can not be changed" 
      end
      
    end
  end
  
