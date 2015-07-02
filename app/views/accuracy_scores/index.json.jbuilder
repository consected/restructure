json.array!(@accuracy_scores) do |accuracy_score|
  json.extract! accuracy_score, :id, :name, :value, :admin_id
  json.url accuracy_score_url(accuracy_score, format: :json)
end
