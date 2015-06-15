json.array!(@player_infos) do |player_info|
  json.extract! player_info, :id, :master_id, :first_name, :last_name, :middle_name, :nick_name, :birth_date, :death_date, :occupation_category, :company, :company_description, :transaction_status, :transaction_substatus, :website, :alternate_website, :twitter_id, :user_id
  json.url player_info_url(player_info, format: :json)
end
