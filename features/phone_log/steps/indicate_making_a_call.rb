
Before do
  setup_database
  
end



When "the user indicates he is calling one of the contact's phone numbers" do
  
  show_top_ranked_phone_log

  select_phone_to_call
  
end

Given "the user has indicated he is calling one of the contact's phone numbers" do

  steps %Q{
    When the user indicates he is calling one of the contact's phone numbers
  }
  expect_phone_log_to_show_contact_number
end

Then "the user sees the call log entry form for the selected phone number" do

  expect_phone_log_to_be_visible

end

Then "the user sees the call log for the contact" do

  expect_phone_log_to_be_visible

end




Given "the user needs to edit or review other player information for the contact" do
  true
end

When "the user views player information and tracker information" do  
  expect(page).to have_tracker_tree_block
end

Then "the user selects specific items to edit" do
  
  edit_player_info_record
end

Then "the user can easily go back to the call log" do

  scroll_to PhoneSetup::PhoneLogBlockCss

end

When "the user has details about the call they made or was made by a rep" do

  true

end

