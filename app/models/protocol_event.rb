class ProtocolEvent < ActiveRecord::Base

  include AdminHandler
  include SelectorCache

  belongs_to :sub_process
  validates :name, presence: true
  validates :sub_process, presence: true
  
  default_scope -> {order :name }
  
  def protocol
    sub_process.protocol if sub_process
  end
  
  def protocol_name
    protocol.name if protocol
  end
  
  def sub_process_name
    sub_process.name if sub_process
  end
  
  def parent_name
    "#{protocol_name} #{sub_process_name}"
  end
    
end
