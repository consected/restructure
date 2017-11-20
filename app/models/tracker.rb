class Tracker < UserBase

  include UserHandler
  include TrackerHandler

  has_many :tracker_histories, inverse_of: :tracker
  belongs_to :item, polymorphic: true

  validate :prevent_protocol_change,  on: :update
  validate :check_protocol_event
  validate :check_sub_process

  validates :protocol, presence: true
  validates :master, presence: true
  validates :event_date, presence: true, if: :sub_process_id?

  # We can't use this next validation, since the error attribute is not translatable, and therefore we can't get sub_process to appear to users as 'status'
  #  validates :sub_process, presence: true, if: :protocol_id?

  # _merged attribute is used to indicate if a tracker record was merged into an existing
  # record on creation
  attr_accessor :_merged

  # Check whether a tracker record with the same protocol already exists for this master
  # If it does then a DB trigger will update the existing record rather than creating a new one.
  # This following method ensures that the latest tracker entry for this protocol is returned,
  # whatever action is taken by the DB triggers behind the scenes.
  def merge_if_exists

    # Get the existing tracker item for the master / protocol pair in the new record (self)
    # If it exists then we handle saving the new record and getting the appropriate response.
    # If it doesn't exist, we return nil
    existing_tracker = self.master.trackers.where(protocol_id: self.protocol_id).take(1)
    if existing_tracker.first
      logger.info "An existing master / protocol pair exists when attempting to merge tracker entry"

      # Save this (new) tracker to ensure it is created
      res = self.save

      if res

        # get the latest tracker item after saving to the database, based on triggered results
        t1 = self.master.trackers.where(protocol_id: self.protocol_id).take(1)
        new_top_tracker = t1.first

        # Indicate that the result should be displayed as a merged item
        new_top_tracker._merged = true

        return new_top_tracker
      elsif !errors || errors.empty?
        # No error was reported. Add one for the user
        logger.warn "Tracker entry could not be merged"
        errors.add :protocol, "tracker could not be merged"
        return nil
      else
        # Errors were already returned. Don't add another one
        logger.warn "Tracker entry could not be merged - errors reported: #{errors.inspect}"
        return nil
      end

    end

    # No existing master / protocol pair existed. Don't return anything so the caller can handle the response appropriately
    logger.info "An existing master / protocol pair does not exist when attempting to merge tracker entry"
    nil
  end

  # does a standard merge_if_exists, but always attempts to save the result
  def merge_if_exists!
    t = merge_if_exists || self
    t.save!
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

      # Exclude where both to and from are blank (since a form update will cause a switch of nil and "") which is meaningless
      unless v.first.blank? && v.last.blank?
        kname = ("#{k.to_s}_name").to_sym

        if record.respond_to? kname
          n = record.class.send("get_#{k}_name".to_s, tov)
          tov = "(#{tov}) #{n}" unless n.is_a?(String) && tov.is_a?(String) && tov.downcase == n.downcase
          n = record.class.send("get_#{k}_name".to_s, fromv)
          fromv = "(#{fromv}) #{n}" unless n.is_a?(String) && fromv.is_a?(String) && fromv.downcase == n.downcase
        end

        fromv = '-' if fromv.blank?
        tov = '-' if tov.blank?

        cp << "#{k.humanize} #{new_rec ? '' : "from #{fromv}"} #{new_rec ? '' : 'to '}#{tov}; "
      end
    end


    # If there were no changes, discard this item. Otherwise, save it.
    if cp.blank?
      return nil
    else
      t.notes = cp
      t.save
    end

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

    # If there were no changes, discard this item. Otherwise, save it.
    if cp.blank?
      return nil
    else
      t.notes = cp
      t.save
    end
  end

  def self.update_tracker type, record

    t = get_or_create_record_updates_tracker record

    t.set_record_updates_sub_process type
    t.set_record_updates_event record

    t.event_date = DateTime.now

    t.item_id = record.id
    t.item_type = record.class.name
    raise "Bad item for tracker (#{type} / #{record.class.name} / #{record.id})" unless t.item

    return t
  end

  def self.add_record_update_entries name, admin, update_type='record'

    begin
      protocol = Protocol.updates.first
      sp = protocol.sub_processes.find_by_name("#{update_type} updates")
      values = []

      name = name.humanize.downcase
    rescue => e
      logger.error "Error finding protocol or sub process for tracker record update. Protocols #{Protocol.count}"
      raise e
    end

    values << {name: "created #{name.downcase}", sub_process_id: sp.id}
    values << {name: "updated #{name.downcase}", sub_process_id: sp.id}


    values.each do |v|
      res = sp.protocol_events.find_or_initialize_by(v)
      unless res.admin
        res.update!(current_admin: admin)
        logger.info "Added protocol event #{v} in #{protocol.id} / #{sp.id}"
      else
        logger.info "Did not add protocol event #{v} in #{protocol.id} / #{sp.id}"
      end
    end
  end


  def set_record_updates_event record
    new_rec = record.id_changed?
    rec_type = "#{new_rec ? 'created' : 'updated'} #{record.class.name.ns_underscore.humanize.downcase}"

    self.protocol_event = Rails.cache.fetch "record_updates_protocol_events_#{self.sub_process.id}_#{rec_type}" do
      self.sub_process.protocol_events.where(name: rec_type).first
    end

    unless self.protocol_event
      raise "Bad protocol_event (#{rec_type}) for tracker #{record}"
    end
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

  def check_protocol_event

    errors.add(:method, ' must be selected') if protocol_event_id.nil? && sub_process && sub_process.protocol_events.length > 0
  end

  def check_sub_process

    errors.add(:status, ' must be selected') if sub_process_id.nil? && protocol
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
