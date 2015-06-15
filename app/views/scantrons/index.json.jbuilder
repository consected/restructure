json.array!(@scantrons) do |scantron|
  json.extract! scantron, :id, :master_id, :scantron_id, :source, :rank, :user_id
  json.url scantron_url(scantron, format: :json)
end
