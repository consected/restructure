json.array!(@general_selections) do |general_selection|
  json.extract! general_selection, :id, :name, :value, :item_type
  json.url general_selection_url(general_selection, format: :json)
end
