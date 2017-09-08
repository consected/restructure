class TrackerHistory < ActiveRecord::Base

  self.table_name = 'tracker_history'
  include UserHandler
  include TrackerHandler
  

  has_one :tracker, inverse_of: :tracker_histories
  belongs_to :item, polymorphic: true
  
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
