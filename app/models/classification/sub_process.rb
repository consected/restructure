class Classification::SubProcess < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  belongs_to :protocol
  has_many :protocol_events

  validates :name, presence: true
  validates :protocol, presence: true

  default_scope -> { order updated_at: :desc}

  def value
    id
  end

  def protocol_name
    protocol ? protocol.name : ''
  end

  def parent_name
    protocol_name
  end

  def self.find_by_name name
    active.where(name: name).first
  end

  # Allows app type import to function
  def protocol_name= name
    self.protocol = Classification::Protocol.find_by_name(name)
  end

  def as_json options={}
    options[:methods] ||= []
    options[:methods] << :protocol_name
    super
  end


end
