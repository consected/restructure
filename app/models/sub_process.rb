class SubProcess < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  belongs_to :protocol
  has_many :protocol_events

  def protocol_name
    protocol ? protocol.name : ''
  end
  
end
