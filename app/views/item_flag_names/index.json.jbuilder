json.array!(@item_flag_names) do |item_flag_name|
  json.extract! item_flag_name, :id, :name, :user_id
  json.url item_flag_name_url(item_flag_name, format: :json)
end
