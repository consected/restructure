class TrackerHistory < UserBase

  self.table_name = 'tracker_history'
  include UserHandler
  include TrackerHandler


  has_one :tracker, inverse_of: :tracker_histories
  belongs_to :item, polymorphic: true

  # Avoids a lot of unnecessary database lookups
  def self.uses_item_flags?
    false
  end

  # Override for latest_tracker_history, where we have no way of getting at the master_user
  # Master is responsible for excluding these items
  def allows_current_user_access_to? perform, with_options=nil
    return true unless master_user
  end

  def as_json extras={}
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
