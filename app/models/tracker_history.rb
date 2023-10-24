# frozen_string_literal: true

# TrackerHistory holds a record for every tracker status event added for a master record
# It provides the full chronological list of tracker events in the front end
# and the underlying table is routinely inserted to outside the app to track participant
# events within a study.
# Both trackers and tracker_history (intentionally singular, despite convention) are supported
# by database triggers that allow inserts and updates into either of them to be reflected
# correctly in the trackers table.
# @see Tracker for more information.
class TrackerHistory < UserBase
  self.table_name = 'tracker_history'
  include UserHandler
  include TrackerHandler

  has_one :tracker, inverse_of: :tracker_histories
  belongs_to :item, polymorphic: true, optional: true

  # Avoids a lot of unnecessary database lookups
  def self.uses_item_flags?(_user)
    false
  end

  def self.category
    :subjects
  end

  # Override for latest_tracker_history, where we have no way of getting at the master_user
  # Master is responsible for excluding these items
  def allows_current_user_access_to?(_perform, _with_options = nil)
    true unless master_user
  end

  # Get completions for a specific master (which must have current_user set)
  def self.completions(master)
    completion_sub_processes = Admin::AppConfiguration.values_for :completion_sub_processes,
                                                                  master.current_user,
                                                                  to: :to_i
    # TODO verify change reorder. What orders in the first place?
    res = master.tracker_histories
                .joins(:protocol, :sub_process)
                .where(sub_process_id: completion_sub_processes)
                .reorder('protocols.name ASC')

    # TODO: remove
    # puts 'TEST SORT', res.to_sql

    res = res.all.map do |r|
      {
        protocol_id: r.protocol_id,
        sub_process_id: r.sub_process_id,
        protocol_name: r.protocol_name,
        sub_process_name: r.sub_process_name
      }
    end

    res.uniq
  end

  def as_json(extras = {})
    extras[:methods] ||= []
    extras[:methods] << :protocol_name
    extras[:methods] << :sub_process_name
    extras[:methods] << :event_name
    extras[:methods] << :record_type_us
    extras[:methods] << :record_type
    extras[:methods] << :record_id
    extras[:methods] << :event_milestone

    super(extras)
  end
end
