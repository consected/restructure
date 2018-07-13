class Classification::Protocol < ActiveRecord::Base

  include AdminHandler
  include SelectorCache

  RecordUpdatesProtocolName = 'Updates'.freeze

  has_many :sub_processes

  default_scope -> { order position: :asc }
  scope :updates, -> { where "name = ? AND (disabled IS NULL OR disabled = FALSE)", RecordUpdatesProtocolName }
  scope :selectable, -> { enabled.where("name <> ?", RecordUpdatesProtocolName)}

  validates :name, presence: true

  def value
    id
  end

  def self.find_by_name name
    active.where(name: name).first
  end

  # A simple method to cache the record that is used to indicate Tracker Updates
  # so that we can quickly and repetitively user this
  def self.record_updates_protocol
    Rails.cache.fetch "record_updates_protocol" do
      enabled.updates.take
    end
  end

end
