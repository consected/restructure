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

end
