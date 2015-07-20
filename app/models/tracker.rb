class Tracker < ActiveRecord::Base
  include UserHandler

  belongs_to :protocol
  belongs_to :sub_process
  belongs_to :protocol_event
  has_many :tracker_histories, inverse_of: :tracker
  before_validation :prevent_protocol_change,  on: :update

  attr_accessor :_merged
  
  def initialize presets={}
    
    # Note: the event date and outcome date are now set dynamically in javascript within the form
    #presets[:event_date] ||= DateTime.now
    
    super
  end
  
  def merge_if_exists
    #t = self.master.trackers.where(protocol_id: self.protocol_id, sub_process_id: self.sub_process_id).take(1)
    t = self.master.trackers.where(protocol_id: self.protocol_id).take(1)
    if t.first
      
      t = t.first
      logger.info "Updating existing tracker record #{t.id} instead of creating a new one"
      logger.debug "With: #{self.inspect}"
      t.sub_process = self.sub_process
      t.protocol_event = self.protocol_event
      t.event_date = self.event_date
      t.notes = self.notes
      t._merged = true
      t.save
      
      return t
    end
    nil
  end
  
  
  def self.track_record_update record
  
    logger.debug "Tracking for #{record}"
    return nil if record.is_a?(Tracker) || record.is_a?(TrackerHistory)
    
    t = update_tracker :record, record
    
        
    cp = ""
    ignore = %w(created_at updated_at user_id user id)
    new_rec = record.id_changed?

    record.changes.reject {|k,v| ignore.include? k}.each {|k,v| cp << "#{k.humanize} #{new_rec ? '' : "from #{v.first || "-"}"} #{new_rec ? '' : 'to '}#{v.last}; " }
    
   
    t.notes = cp
    res = t.save
    logger.debug "Tracking result: #{res}"
    res
  end
  
  def self.track_flag_update record, added_flags, removed_flags
  
    logger.debug "Tracking for #{record}"
    return nil if record.is_a?(Tracker) || record.is_a?(TrackerHistory)
    
    t = update_tracker :flag, record
    
    
    cp = ""
    
    if added_flags.length > 0
      cp << "added  flags: "
      added_flags.each {|k| cp << "#{ItemFlagName.find(k).name}; " }
    end
    
    if removed_flags.length > 0
      cp << "removed flags: "
      removed_flags.each {|k| cp << "#{ItemFlagName.find(k).name}; " }
    end
    
    t.notes = cp
    res = t.save
    logger.debug "Tracking result: #{res}"
    res
  end
  
  def self.update_tracker type, record
    
    new_rec = record.id_changed?

    t = record.master.trackers.where(protocol_id: Protocol.record_updates_protocol).first
    
    # If not found, remember this is a new tracker
    new_tracker = !t
    
    t ||= record.master.trackers.new 
    
    t.protocol = Protocol.record_updates_protocol if new_tracker
    #t.event = "flags update"
    
    t.sub_process = t.protocol.sub_processes.where(name: "#{type} updates").first
    
    rec_type = "#{new_rec ? 'created' : 'updated'} #{record.class.name.underscore.humanize.downcase}"
    
    #logger.debug "attempting to get rec for #{rec_type}: #{t.sub_process.protocol_events.where(name: rec_type).first.inspect}"
    
    t.protocol_event = t.sub_process.protocol_events.where(name: rec_type).first
    
    t.event_date = DateTime.now
    
    
    return t
  end
  
  def protocol_name
    return nil unless self.protocol
    self.protocol.name
  end
  
  def protocol_position
    return nil unless self.protocol
    self.protocol.position
  end
  
  def sub_process_name
    return nil unless self.sub_process
    self.sub_process.name
  end
  
  def event_name
    return nil unless self.protocol_event
    self.protocol_event.name
  end
  
  def tracker_history_length
    
    r = tracker_histories.length
    r
  end

  def prevent_protocol_change 
    if protocol_id_changed? && self.persisted?
      errors.add(:protocol, "change not allowed!")
    end
  end

  
  def as_json extras={}
    extras[:methods] ||= []
    extras[:methods] << :protocol_name
    extras[:methods] << :protocol_position
    extras[:methods] << :sub_process_name
    extras[:methods] << :event_name
    extras[:methods] << :tracker_history_length
    extras[:methods] << :_merged
      
    super(extras)
  end
  
end
