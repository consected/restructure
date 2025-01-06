# frozen_string_literal: true

class Classification::Protocol < ActiveRecord::Base
  #  App type is not required
  def self.app_type_not_required
    true
  end

  include AppTyped
  include AdminHandler
  include SelectorCache
  include PositionHandler

  RecordUpdatesProtocolName = 'Updates'

  has_many :sub_processes

  default_scope -> { order position: :asc }
  scope :updates, -> { enabled.where(name: RecordUpdatesProtocolName) }
  scope :selectable, -> { enabled.where('name <> ?', RecordUpdatesProtocolName) }

  validates :name, presence: true
  before_save :reset_memos

  def self.position_attribute
    :position
  end

  def position_group
    { app_type_id: }
  end

  def value
    id
  end

  def to_s
    name
  end

  # Use #select so we don't have to requery for each request for this scope
  def self.find_by_name(name)
    active.select { |r| r.name == name }.first
  end

  # A simple method to memoize the record that is used to indicate Tracker Updates
  # so that we can quickly and repetitively use this
  def self.record_updates_protocol
    @record_updates_protocol ||= enabled.updates.reload.take
  end

  def self.reset_record_updates_protocol!
    @record_updates_protocol = nil
  end

  def reset_memos
    self.class.reset_memos
  end

  def self.reset_memos
    # @all_active = nil
    Classification::SubProcess.reset_memos
    Classification::ProtocolEvent.reset_memos
    reset_record_updates_protocol!
  end
end
