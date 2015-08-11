class Tracker < ActiveRecord::Base
  include UserHandler
  include TrackerHandler
  
  has_many :tracker_histories, inverse_of: :tracker

  before_validation :prevent_protocol_change,  on: :update
  validates :protocol, presence: true
  validates :protocol_event_id, presence: true, if: :event_date?  
  validates :event_date, presence: true, if: :protocol_event_id?
  validates :sub_process, presence: true, if: :protocol_event_id?
  
  # _merged attribute is used to indicate if a tracker record was merged into an existing
  # record on creation
  attr_accessor :_merged
  
  # Check whether a tracker record with the same protocol already exists for this master
  # If it does then we will update the existing record rather than creating a new one.
  # From a user perspective this ensures that the current status of the tracker always maintains only one
  # state for a protocol.
  def merge_if_exists
    
    t = self.master.trackers.where(protocol_id: self.protocol_id).take(1)
    if t.first
      
      t = t.first
      logger.info "Updating existing tracker record #{t.id} instead of creating a new one"

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
  
  # Called by UserHandler managed records to save the latest update to the tracker
  def self.track_record_update record
  
    return nil if record.is_a?(Tracker) || record.is_a?(TrackerHistory)
    
    t = update_tracker :record, record
        
    cp = ""
    ignore = %w(created_at updated_at user_id user id)
    new_rec = record.id_changed?

    record.changes.reject {|k,v| ignore.include? k}.each do |k,v| 
      fromv = v.first
      tov = v.last
      
      kname = ("#{k.to_s}_name").to_sym
      
      if record.respond_to? kname      
        tov = "#{tov} - #{record.class.send("get_#{k}_name".to_s, tov)}" 
        fromv = "#{fromv} - #{record.class.send("get_#{k}_name".to_s, fromv)}" 
        
      end
      
      cp << "#{k.humanize} #{new_rec ? '' : "from #{fromv || "-"}"} #{new_rec ? '' : 'to '}#{tov}; " 
    end
    
   
    t.notes = cp
    t.save
   
  end
  
  # Called by item flag controller to save the aggregate set of item_flag changes to the tracker
  def self.track_flag_update record, added_flags, removed_flags
  
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
    res
  end
  
  def self.update_tracker type, record
    
    t = get_or_create_record_updates_tracker record
    
    t.set_record_updates_sub_process type
    t.set_record_updates_event record  
    
    t.event_date = DateTime.now
    
    t.item_id = record.id    
    t.item_type = record.class.name
    raise "Bad item for tracker (#{type})" unless t.item
    
    return t
  end
  
  def set_record_updates_event record
    new_rec = record.id_changed?    
    rec_type = "#{new_rec ? 'created' : 'updated'} #{record.class.name.underscore.humanize.downcase}"
    
    self.protocol_event = Rails.cache.fetch "record_updates_protocol_events_#{rec_type}" do
      self.sub_process.protocol_events.where(name: rec_type).first
    end
    
    raise "Bad protocol_event (#{rec_type}) for tracker #{record}" unless self.protocol_event
    
  end
  
  def set_record_updates_sub_process type
    
    self.sub_process = Rails.cache.fetch "record_updates_sub_process_#{type}" do
      Protocol.record_updates_protocol.sub_processes.where(name: "#{type} updates").first
    end
    
    raise "Bad sub_process for tracker (#{type})" unless self.sub_process
    
  end
  
  def self.get_or_create_record_updates_tracker record
    
    t = record.master.trackers.where(protocol_id: Protocol.record_updates_protocol).first    
    t ||= record.master.trackers.new protocol: Protocol.record_updates_protocol    
    t
    
  end
  
  def tracker_history_length
    
    tracker_histories.length
    
  end

  def prevent_protocol_change 
    
    errors.add(:protocol, "change not allowed!") if protocol_id_changed? && self.persisted?
    
  end
    
  
  def as_json extras={}
    extras[:methods] ||= []
    extras[:methods] << :protocol_name
    extras[:methods] << :protocol_position
    extras[:methods] << :sub_process_name
    extras[:methods] << :event_name
    extras[:methods] << :event_milestone
    extras[:methods] << :tracker_history_length
    extras[:methods] << :record_type_us
    extras[:methods] << :record_type
    extras[:methods] << :record_id
    extras[:methods] << :_merged
      
    super(extras)
  end
  
end
