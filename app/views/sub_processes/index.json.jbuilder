json.array!(@sub_processes) do |sub_process|
  json.extract! sub_process, :id, :name, :disabled, :protocol_id, :admin_id
  json.url sub_process_url(sub_process, format: :json)
end
