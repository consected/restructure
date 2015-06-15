json.array!(@addresses) do |address|
  json.extract! address, :id, :master_id, :street, :street2, :street3, :city, :state, :zip, :source, :rank, :rec_type, :user_id
  json.url address_url(address, format: :json)
end
