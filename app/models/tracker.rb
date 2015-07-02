class Tracker < ActiveRecord::Base
  include UserHandler

  belongs_to :protocol
  has_many :tracker_histories, inverse_of: :tracker

  
  def initialize presets={}
    
    presets[:event_date] ||= DateTime.now
    
    super
  end
  
  
  def self.track_record_update record
    
    return nil if record.is_a?(Tracker) || record.is_a?(TrackerHistory)
    
    t = record.master.trackers.where(protocol_id: Protocol.record_updates_protocol).first
    
    # If not found, remember this is a new tracker
    new_tracker = !t
    
    t ||= record.master.trackers.new 
    
    new_rec = record.id_changed?
    
    rec_type = "#{new_rec ? 'created' : 'updated'} #{record.class.name.underscore.humanize.downcase}"
    
    logger.debug "Tracking #{rec_type} update"
    #ev = ProtocolEvent.find_by_name rec_type
    
    t.protocol = Protocol.record_updates_protocol if new_tracker
    t.event = "record update"
    t.outcome =  rec_type#ev.name
    t.event_date = DateTime.now
    t.outcome_date = DateTime.now
    cp = ""
    ignore = %w(created_at updated_at user id)
    record.changes.reject {|k,v| ignore.include? k}.each {|k,v| cp << "#{k.humanize} #{new_rec ? '' : "from #{v.first || "-"}"} #{new_rec ? '' : 'to '}#{v.last}; " }
    
    logger.debug "Tracking user update to record with #{cp} in #{rec_type}"
    
    t.notes = cp
    t.save
  end
  
  
  def protocol_name
    return nil unless self.protocol
    self.protocol.name
  end
  
  def tracker_history_length
    
    r = tracker_histories.length
    r
  end
  
  def as_json extras={}
    extras[:methods] ||= []
    extras[:methods] << :protocol_name
    extras[:methods] << :tracker_history_length
      
    super(extras)
  end
  
end
