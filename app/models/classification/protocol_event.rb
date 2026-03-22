# frozen_string_literal: true

class Classification::ProtocolEvent < ActiveRecord::Base
  self.table_name = 'protocol_events'
  include AdminHandler
  include SelectorCache

  belongs_to :sub_process
  validates :name, presence: true
  validates :sub_process, presence: true
  before_save :reset_memos

  default_scope -> { preload(sub_process: [:protocol]).order(:name) }

  def value
    id
  end

  def protocol
    @protocol ||= sub_process&.protocol
  end

  def protocol_name
    @protocol_name ||= protocol&.name
  end

  def sub_process_name
    @sub_process_name ||= sub_process&.name
  end

  def parent_name
    "#{protocol_name} #{sub_process_name}"
  end

  # Use #select so we don't have to requery for each request for this scope
  def self.find_by_name(name)
    active.select { |r| r.name == name }.first
  end

  # Allows app type import to function
  def sub_process_name=(name)
    Classification::Protocol.reset_memos
    self.sub_process = @protocol.sub_processes.find_by_name(name) if @protocol
  end

  # Allows app type import to function
  def protocol_name=(name)
    Classification::Protocol.reset_memos
    @protocol = Classification::Protocol.find_by_name(name)
  end

  def as_json(options = {})
    options[:methods] ||= []
    options[:methods] << :protocol_name
    options[:methods] << :sub_process_name

    super
  end

  def reset_memos
    self.class.reset_memos
  end

  def self.reset_memos
    # @all_active = nil
  end
end
