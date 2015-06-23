json.array!(@colleges) do |college|
  json.extract! college, :id, :name, :synonym_for_id
  json.url college_url(college, format: :json)
end
