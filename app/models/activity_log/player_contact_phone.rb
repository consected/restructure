class ActivityLog::PlayerContactPhone < ActiveRecord::Base

  # the activity log models both belong to their original item directly, such as
  # a player_contact, while also belonging directly to a master.
  # In this way, a master can see all logged activities, without having to
  # scan through the intermediate objects

  def self.parent_type
    :player_contact
  end

  def self.parent_rec_type
    :phone
  end

  include WorksWithItem
  include ActivityLogHandler

  belongs_to :master, inverse_of: assoc_inverse

end

