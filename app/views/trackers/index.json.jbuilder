json.array!(@trackers) do |tracker|
  json.extract! tracker, :id, :master_id, :protocol_id, :event, :event_date, :c_method, :outcome, :outcome_date, :user_id
  json.url tracker_url(tracker, format: :json)
end
