json.array!(@protocols) do |protocol|
  json.extract! protocol, :id, :name, :user_id
  json.url protocol_url(protocol, format: :json)
end
