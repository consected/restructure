json.array!(@player_contacts) do |player_contact|
  json.extract! player_contact, :id, :master_id, :data, :pcdata, :source, :rank, :pcdate, :active
  json.url player_contact_url(player_contact, format: :json)
end
