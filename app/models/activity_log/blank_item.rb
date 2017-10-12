class ActivityLog::BlankItem < ActiveRecord::Base

  # the activity log models both belong to their original item directly, such as
  # a player_contact, while also belonging directly to a master.
  # In this way, a master can see all logged activities, without having to
  # scan through the intermediate objects

  def self.table_name
    'activity_log_player_contact_phones'
  end

  def self.parent_type
    :master
  end

  def self.parent_rec_type

  end

  def self.action_when_attribute
    :called_when
  end

  def self.activity_log_name
    'Activity Log'
  end

  include TrackerHandler
  include WorksWithItem
  include ActivityLogHandler

  belongs_to :master, inverse_of: assoc_inverse



end
