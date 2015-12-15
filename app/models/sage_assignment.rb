class SageAssignment < ActiveRecord::Base
  include UserHandler
  include ExternalIdHandler

  validates :sage_id, presence: true,  length: {is: 10}
  validate :sage_id_tests    
  default_scope -> {order id: :desc}
  scope :assigned, -> {where "master_id is not null"}
  scope :unassigned, -> {where "master_id is null"}
  after_save :return_all
  
  attr_accessor :create_count, :just_assigned
  
  class NoUnassignedAvailable < FphsException
    def message
      "No available Sage IDs for assignment"
    end
  end 

  def self.prevent_edit?
    true
  end

  
  def self.external_id_attribute
    :sage_id
  end

  def self.id_formatter
    'format_sage_id'
  end
  
  def self.label
    'Sage ID'
  end
  
  def return_all
    self.multiple_results = self.master.sage_assignments.all if self.master
  end
  
  # We assign the next available 
  def self.assign_next_available_id master
    
    sage_assignment = self.next_available
    raise NoUnassignedAvailable  unless sage_assignment
    sage_assignment.assigned_by = "fphsapp"
    sage_assignment.master = master
    sage_assignment.just_assigned = true
    sage_assignment
    
  end
  
  def self.next_available
    s = SageAssignment.unassigned.unscope(:order).first
    logger.info "Got next available Sage id #{s.id}"
    s
    
  end
    
  
  def self.generate_ids admin, count=10
    
    raise "Only admins can perform this function" unless admin && admin.enabled?
    
    res = []
    
    (1..count).each do |c|      
      
      begin
        s = SecureRandom.random_number(8_999_999_999) + 1_000_000_000
        
        item = SageAssignment.new(sage_id: s.to_s, admin_id: admin.id)

        item.no_track = true      
        item.save!
        res << item
      rescue PG::UniqueViolation => e
        logger.info "Failed to create a Sage Assignment record due to an random duplicate"
      end  
      
    end
    
    res
  end
  
  def self.master_build owner, att=nil
    if att
      SageAssignment.assign_next_available_id owner
    else
      SageAssignment.new master: owner
    end
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
  
