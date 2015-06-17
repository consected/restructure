class Tracker < ActiveRecord::Base
  include UserHandler

  belongs_to :protocol
  
  
  
  
  def protocol_name
    return nil unless self.protocol
    self.protocol.name
  end
  
  def as_json
    super(methods: :protocol_name)
  end
  
end
