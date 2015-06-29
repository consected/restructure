json.array!(@protocol_outcomes) do |protocol_outcome|
  json.extract! protocol_outcome, :id, :name, :protocol_id, :admin_id
  json.url protocol_outcome_url(protocol_outcome, format: :json)
end
