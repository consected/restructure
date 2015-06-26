json.array!(@protocol_events) do |protocol_event|
  json.extract! protocol_event, :id, :name, :protocol_id, :user_id
  json.url protocol_event_url(protocol_event, format: :json)
end
