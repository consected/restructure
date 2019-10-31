module TrackerHandler

  extend ActiveSupport::Concern

  included do
    belongs_to :protocol, class_name: 'Classification::Protocol'
    belongs_to :sub_process, class_name: 'Classification::SubProcess'
    belongs_to :protocol_event, class_name: 'Classification::ProtocolEvent'

  end


  def protocol_name
    return nil unless self.protocol
    self.protocol.name
  end

  def protocol_position
    return nil unless self.protocol
    self.protocol.position
  end

  def sub_process_name
    return nil unless self.sub_process
    self.sub_process.name
  end

  def event_name
    return nil unless self.protocol_event
    self.protocol_event.name
  end

  def protocol_event_name
    event_name
  end

  def event_milestone
    return nil unless self.protocol_event
    self.protocol_event.milestone
  end

  def event_description
    return nil unless self.protocol_event
    self.protocol_event.description
  end

  # get the underlying item_type related to the polymorphic association
  # this accessor was overridden elsewhere
  def record_type
    self.attributes['item_type']
  end

  # get the underlying item_id related to the polymorphic association
  # this accessor was overridden elsewhere
  def record_id
    self.attributes['item_id']
  end

  def record_type_us
    return unless self.record_type
    self.record_type.ns_underscore
  end

  def no_master_association
    false
  end

end
