class Classification::SubProcess < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  belongs_to :protocol
  has_many :protocol_events

  validates :name, presence: true
  validates :protocol, presence: true
  before_save :reset_memos

  default_scope -> { preload(:protocol, :protocol_events).order(updated_at: :desc) }

  def value
    id
  end

  def to_s
    "#{protocol_name} / #{name}"
  end

  def protocol_name
    protocol&.name || ''
  end

  def parent_name
    protocol_name
  end

  # Use #select so we don't have to requery for each request for this scope
  def self.find_by_name(name)
    active.select { |r| r.name == name }.first
  end

  # Allows app type import to function
  def protocol_name=(name)
    Classification::Protocol.reset_memos
    self.protocol = Classification::Protocol.find_by_name(name)
  end

  def as_json(options = {})
    options[:methods] ||= []
    options[:methods] << :protocol_name
    super
  end

  def reset_memos
    self.class.reset_memos
  end

  def self.reset_memos
    # @all_active = nil
  end
end
