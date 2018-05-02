require "#{Rails.root}/db/seeds/0_tracker_updates_protocol.rb"
  
def auto_admin 
  @admin ||= Admin.find_or_create_by email: 'auto-admin@dummy.aaa'
end

def log txt
  puts txt
  Rails.logger.info txt
end

auto_admin

class AddAdminToSageAssignments < ActiveRecord::Migration
  def change
    add_reference :sage_assignments, :admin, index: true, foreign_key: true
    
    auto_admin = Admin.find_or_create_by email: 'auto-admin@dummy.aaa'
    auto_admin.save!
    Seeds::TrackerUpdatesProtocol.setup 
    
    protocol = Classification::Protocol.where(name: 'Updates').enabled.first
    protocol.current_admin = auto_admin
    sp = protocol.sub_processes.find_by(name: 'record updates')
    sp.current_admin = auto_admin
    pe = sp.protocol_events.find_or_initialize_by({name: "created sage assignment", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil})
    pe.current_admin = auto_admin      
    pe.save!
    pe = sp.protocol_events.find_or_initialize_by({name: "updated sage assignment", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil})
    pe.current_admin = auto_admin      
    pe.save!
    
  end
end
