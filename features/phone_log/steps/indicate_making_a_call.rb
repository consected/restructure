
Before do
  setup_database
  
end

Given "the contact has one or more phone number records" do

  expect(top_ranked_phone).not_to be nil
  
end

When "the user indicates he is calling one of the contact's phone numbers" do
  
  show_top_ranked_phone_log

  make_call_to_selected_phone

  expect_phone_log_to_be_visible

  
end

Then "the user sees the call log for the contact" do

  expect_phone_log_to_be_visible

end


Given "the user has indicated he is calling one of the contact's phone numbers" do

  steps %Q{
    When the user indicates he is calling one of the contact's phone numbers
  }
  expect_phone_log_to_show_contact_number
end

Given "the user needs to edit or review other player information for the contact" do
  true
end

When "the user views player information and tracker information" do
  expect(page).to have_selector('.table.tracker-tree-results', visible: true)
end

Then "the user selects specific items to edit" do
  
  edit_player_info_record
end

Then "the user can easily go back to the call log" do

  scroll_to_phone_log
 
end