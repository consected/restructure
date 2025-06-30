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
  after_save :create_activity_tracker_events

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

  def create_activity_tracker_events
    ActivityLog.active.each do |a|
      a.current_admin = current_admin
      a.update_tracker_events
    end
  end

  #
  # Copy sub_processes and protocol_events from source protocol
  # @param [Classification::Protocol] source_protocol - protocol to copy from
  # @return [Classification::Protocol] self
  def copy_from(source_protocol)
    raise FphsException, "Can't copy protocol sub processes to self" if source_protocol.id == id

    added = {}
    transaction do
      # Copy sub_processes
      source_protocol.sub_processes.enabled.reload.each do |source_sub|
        new_sub = sub_processes.reload.find_by(name: source_sub.name)
        sub_existed = !!new_sub
        if new_sub
          use_name = "#{new_sub.name} (existing)"
        else
          new_sub = sub_processes.create!(
            name: source_sub.name,
            current_admin: current_admin
          )
          use_name = new_sub.name
        end
        added[use_name] = []

        # Copy protocol_events for this sub_process
        source_sub.protocol_events.enabled.reload.each do |source_event|
          next if new_sub.protocol_events.reload.exists?(name: source_event.name)

          new_pe = new_sub.protocol_events.create!(
            name: source_event.name,
            milestone: source_event.milestone,
            description: source_event.description,
            current_admin: current_admin
          )

          added[use_name] << new_pe.name
        end

        added.delete(use_name) if sub_existed && added[use_name].empty?
      end
    end

    reset_memos
    added
  end
end
