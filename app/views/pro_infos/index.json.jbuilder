json.array!(@pro_infos) do |pro_info|
  json.extract! pro_info, :id, :master_id, :user_id
  json.url pro_info_url(pro_info, format: :json)
end
