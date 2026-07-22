# frozen_string_literal: true

# Implement status tracker functionality, recording status events for
# a master record.
# A three level hierarchy is used to classify status entries in the database,
# corresponding to lookup tables of predefined values:
#
# - protocol
# - sub_process
# - protocol_event *optional*
#
# These actually correspond to more meaningful terms:
#
# - protocol (or study)
# - event
# - method *optional*
#
# The third level is optional if no predefined values are available for it
#
# The *trackers* table / model only contains a single entry for a protocol, showing
# the latest sub_process / protocol_event entry based on the event date. This
# is effectively a surface level view onto the tracker status events.
# The tracker_history (note, not pluralized against convention) contains all
# protocol / sub_process / protocol_event entries, including the current one. This
# table should be used when checking if a status event has occurred against a
# master record.
#
# Note: the trackers "table" is actually a database view derived from tracker_history.
# Inserts are handled by an INSTEAD OF trigger that redirects to tracker_history.
# The view derives the latest entry per (master_id, protocol_id) using:
#   ORDER BY event_date::date DESC NULLS LAST, tracker_history.id DESC
# This ensures the ordering rule exists in exactly one place.
# See: https://github.com/consected/restructure/issues/941
class Tracker < UserBase
  # Explicitly set primary key since Rails can't auto-detect it from a view
  self.primary_key = 'id'

  include UserHandler
  include TrackerHandler

  # Explicitly set primary key since trackers is now a view
  # and Rails cannot auto-detect the primary key from views
  self.primary_key = 'id'

  has_many :tracker_histories, inverse_of: :tracker
  belongs_to :item, polymorphic: true, optional: true

  validate :prevent_protocol_change, on: :update
  validate :check_protocol_event
  validate :check_sub_process

  validates :protocol, presence: true
  validates :master, presence: true
  validates :event_date, presence: true, if: :sub_process_id?

  # We can't use this next validation, since the error attribute is not translatable,
  # and therefore we can't get sub_process to appear to users as 'status'
  #  validates :sub_process, presence: true, if: :protocol_id?

  # _merged attribute is used to indicate if a tracker record was merged into an existing
  # record on creation
  attr_accessor :_merged, :saving_update

  # Avoids a lot of unnecessary database lookups
  def self.uses_item_flags?(_user)
    false
  end

  def self.category
    :subjects
  end

  # Check whether a tracker record with the same protocol already exists for this master
  # If it does then a DB trigger will update the existing record rather than creating a new one.
  # This following method ensures that the latest tracker entry for this protocol is returned,
  # whatever action is taken by the DB triggers behind the scenes.
  def merge_if_exists
    # Get the existing tracker item for the master / protocol pair in the new record (self)
    # If it exists then we handle saving the new record and getting the appropriate response.
    # If it doesn't exist, we return nil
    existing_tracker = master.trackers.where(protocol_id:).take(1)
    if existing_tracker.first
      logger.info 'An existing master / protocol pair exists when attempting to merge tracker entry'

      # Save this (new) tracker to ensure it is created
      res = save

      if res

        # get the latest tracker item after saving to the database, based on triggered results
        t1 = master.trackers.where(protocol_id:).take(1)
        new_top_tracker = t1.first

        # Indicate that the result should be displayed as a merged item
        new_top_tracker._merged = true

        return new_top_tracker
      elsif !errors || errors.empty?
        # No error was reported. Add one for the user
        logger.warn 'Tracker entry could not be merged'
        errors.add :protocol, 'tracker could not be merged'
        return nil
      else
        # Errors were already returned. Don't add another one
        logger.warn "Tracker entry could not be merged - errors reported: #{errors.inspect}"
        return nil
      end

    end

    # No existing master / protocol pair existed. Don't return anything so the caller can handle the response appropriately
    logger.info 'An existing master / protocol pair does not exist when attempting to merge tracker entry'
    nil
  end

  # does a standard merge_if_exists, but always attempts to save the result
  def merge_if_exists!
    t = merge_if_exists || self
    t.save!
  end

  #
  # Called by UserHandler managed records to save the latest update to the tracker
  # in the Updates protocol
  def self.track_record_update(record)
    return nil if record.is_a?(Tracker) || record.is_a?(TrackerHistory)

    # Get a prepared tracker instance to update with changes. This may
    # be a new or existing tracker record, although it doesn't really matter
    # to the rest of the functionality
    t = update_tracker :record, record

    cp = ''
    ignore = %w[created_at updated_at user_id user id]
    new_rec = record.id_changed?

    record.saved_changes.reject { |k, _v| ignore.include? k }.each do |k, v|
      fromv = v.first
      tov = v.last

      # Exclude where both to and from are blank (since a form update will cause a switch of nil and "") which is meaningless
      next if v.first.blank? && v.last.blank?

      kname = :"#{k}_name"

      get_name = "get_#{k}_name"
      if record.respond_to?(kname) && record.class.respond_to?(get_name)
        n = record.class.send(get_name, tov)
        tov = "(#{tov}) #{n}" unless n.is_a?(String) && tov.is_a?(String) && tov.downcase == n.downcase
        n = record.class.send(get_name.to_s, fromv)
        fromv = "(#{fromv}) #{n}" unless n.is_a?(String) && fromv.is_a?(String) && fromv.downcase == n.downcase
      end

      fromv = '-' if fromv.blank?
      tov = '-' if tov.blank?

      cp += "#{k.humanize} #{"from #{fromv}" unless new_rec} #{'to ' unless new_rec}#{tov}; "
    end

    # If there were no changes, discard this item. Otherwise, save it.
    return nil if cp.blank?

    t.notes = cp
    t.saving_update = true
    t.save
  end

  # Override HandlesUserBase#check_can_save to allow track_record_update
  # to save without the user having create user access control on the Trackers table
  def check_can_save
    if saving_update
      self.saving_update = false
      return true
    end

    super
  end

  # Called by item flag controller to save the aggregate set of item_flag changes to the tracker
  def self.track_flag_update(record, added_flags, removed_flags)
    return nil if record.is_a?(Tracker) || record.is_a?(TrackerHistory)

    t = update_tracker :flag, record
    cp = ''

    unless added_flags.empty?
      cp += 'added  flags: '
      added_flags.each { |k| cp += "#{Classification::ItemFlagName.find(k).name}; " }
    end

    unless removed_flags.empty?
      cp += 'removed flags: '
      removed_flags.each { |k| cp += "#{Classification::ItemFlagName.find(k).name}; " }
    end

    # If there were no changes, discard this item. Otherwise, save it.
    if cp.blank?
      nil
    else
      t.notes = cp
      t.save
    end
  end

  #
  # Summaries of updates to records and flags are recorded into the tracker
  # to provide full context to any changes and status events, allowing users
  # a single place to find changes that may have been made to any record or flag
  # associated with a master record.
  # Simply add a record to the tracker, of a certain type based on the
  # update being recorded.
  # @param [Symbol] type - :record or :flag
  # @param [UserBase] record - the instance created or updated so data can be summarized
  # @return [Tracker] returns the new tracker record
  def self.update_tracker(type, record)
    t = get_or_create_record_updates_tracker record

    t.set_record_updates_sub_process type
    t.set_record_updates_event record

    t.event_date = DateTime.now

    t.item_id = record.id
    t.item_type = record.class.name

    # We no longer raise on a bad item, since in most cases this just can't happen,
    # but for special cases, such as dynamic model views, the record may have disappeared before
    # the tracker item for it can be added. Record the tracker for information, but don't
    # force an unnecessary failure.
    # raise "Bad item for tracker (#{type} / #{record.class.name} / #{record.id})" unless t.item

    t
  end

  #
  # Generate the protocol / sub process  / protocol event entries that will be
  # used by implementations when updating and creating records, and subsequently tracking
  # those changes in the tracker history.
  # @param [String] name - to be humanized and downcased for tracker name
  # @param [Admin] admin - current admin
  # @param [String] update_type - type of update tracker to add: 'record' or 'flag'
  # @param [nil|true] no_create - default: nil - set to true to avoid creating new entries
  #                               and just check if entries already existed or were created
  # @return [Array{true|false, ...}] a true|false array for created.., updated... entries already existing
  def self.add_record_update_entries(name, admin, update_type = 'record', no_create: nil)
    begin
      protocol = Classification::Protocol.updates.reload.first
      raise FphsException, 'No "Updates" protocol found' unless protocol

      sp = protocol.sub_processes.active.reload.find_by_name("#{update_type} updates")&.reload
      raise FphsException, "No sub_process found for 'Updates/#{update_type} updates'" unless sp

      values = []

      name = name.humanize.downcase
    rescue StandardError => e
      logger.error "Error finding protocol or sub process for tracker record update. Protocols #{Classification::Protocol.count}"
      raise e
    end

    values << { name: "created #{name.downcase}", sub_process_id: sp.id }
    values << { name: "updated #{name.downcase}", sub_process_id: sp.id }

    values.map do |v|
      res = sp.protocol_events.active.find_or_initialize_by(v)
      if res.admin_id
        # logger.info "Did not add protocol event #{v} in #{protocol.id} / #{sp.id}"
        true
      else
        res.update!(current_admin: admin) unless no_create
        logger.info "Added protocol event #{v} in #{protocol.id} / #{sp.id}"
        false
      end
    end
  end

  # Find the protocol_events record that matches the rec_type and set the protocol_event attribute in this tracker
  def set_record_updates_event(record, first_attempt: true)
    # Decide if this is a new or updated record. Check both id_changed? and save_change_to_id? since we can't be sure
    # if we'll be in an after_save or after_commit callback
    new_rec = record.id_changed? || record.saved_change_to_id?
    rec_type = "#{new_rec ? 'created' : 'updated'} #{ModelReference.record_type_to_ns_table_name(record.class).humanize.downcase}"

    self.protocol_event = sub_process.protocol_events.find_by_name(rec_type)

    return if protocol_event

    # Stop things breaking unnecessarily
    if first_attempt
      msg = 'Tracker needs to retry getting create/update protocol events'
      logger.warn msg
      puts msg if Rails.env.test?
      Classification::Protocol.reset_memos
      sub_process.reload.protocol_events.reload
      return set_record_updates_event(record, first_attempt: false)
    end

    puts "Bad Protocol Event: #{rec_type}: #{record.attributes}" if Rails.env.test?
    raise "Bad protocol_event (#{rec_type}) for tracker #{record}. If you believe it should exist, " \
          'check double spacing is correct in the definition for namespaced classes.'
  end

  def self.sub_process_for(type)
    Classification::Protocol.record_updates_protocol.sub_processes.find_by_name("#{type} updates")
  end

  #
  # The sub_process attribute is set from the cache where possible to avoid unnecessary lookups
  # to find the Updates / flag or Updates / record subprocess to be assigned to a new tracker entry
  def set_record_updates_sub_process(type)
    self.sub_process = self.class.sub_process_for(type)

    raise "Bad sub_process for tracker (#{type})" unless sub_process
  end

  #
  # Returns the tracker entry corresponding to the Updates protocol, if it exists, otherwise creates
  # sets up a new instance for this protocol_id.
  # This reflects the fact that trackers only show a single entry for each protocol, so updates
  # will probably only update the existing one after the very first update item has been created.
  # Reality is that the underlying DB triggers would handle this appropriately even if we just
  # blindly created a new tracker entry without checking if one already existed.
  def self.get_or_create_record_updates_tracker(record)
    t = record.master.trackers.where(protocol_id: Classification::Protocol.record_updates_protocol).first
    t ||= record.master.trackers.new protocol: Classification::Protocol.record_updates_protocol
    t
  end

  def tracker_history_length
    tracker_histories.count
  end

  def prevent_protocol_change
    errors.add(:protocol, 'change not allowed!') if protocol_id_changed? && persisted?
  end

  def check_protocol_event
    return unless protocol_event_id.nil? && sub_process && !sub_process.protocol_events.empty?

    errors.add(:method, ' must be selected')
  end

  def check_sub_process
    errors.add(:status, ' must be selected') if sub_process_id.nil? && protocol
  end

  def tracker_completions
    master.tracker_completions
  end

  def as_json(extras = {})
    extras = extras.dup
    extras[:include] ||= {}
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

    extras[:methods] << :tracker_completions

    super
  end
end
