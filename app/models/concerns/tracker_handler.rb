# frozen_string_literal: true

module TrackerHandler
  extend ActiveSupport::Concern

  included do
    belongs_to :protocol, class_name: 'Classification::Protocol', optional: true
    belongs_to :sub_process, class_name: 'Classification::SubProcess', optional: true
    belongs_to :protocol_event, class_name: 'Classification::ProtocolEvent', optional: true
    default_scope -> { eager_load(:protocol_event, :sub_process, :protocol) }
  end

  def protocol_name
    return nil unless protocol

    protocol.name
  end

  def protocol_position
    return nil unless protocol

    protocol.position
  end

  def sub_process_name
    return nil unless sub_process

    sub_process.name
  end

  def event_name
    return nil unless protocol_event

    protocol_event.name
  end

  def protocol_event_name
    event_name
  end

  def event_milestone
    return nil unless protocol_event

    protocol_event.milestone
  end

  def event_description
    return nil unless protocol_event

    protocol_event.description
  end

  # get the underlying item_type related to the polymorphic association
  # this accessor was overridden elsewhere
  def record_type
    attributes['item_type']
  end

  # get the underlying item_id related to the polymorphic association
  # this accessor was overridden elsewhere
  def record_id
    attributes['item_id']
  end

  def record_type_us
    return unless record_type

    record_type.ns_underscore
  end

  def no_master_association
    false
  end
end
