
Before do
  setup_database
end

When "the user indicates he wants to view the player's call log" do
  raise "player does not have any call log items to view" if @master.activity_log__player_contact_phones.length == 0
  show_top_ranked_phone_log
  expect_phone_log_to_show_contact_number
end



When "the user selects a phone number in the call log" do
  show_top_ranked_phone_log
end


Then "the user sees the call logs for the phone number selected" do
  expect_phone_log_to_be_visible

  expect_phone_log_to_highlight_selected_phone_number
end
