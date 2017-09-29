When "the contact answers a call from a user and they speak about the reason for the call" do  
  mark_outgoing_call 'To Player'
end

Then "the user records that he spoke to the contact successfully about the matter" do
  mark_call_status 'Call Connected'
  mark_next_step_status 'Complete'
end


When "the contact answers the call but he does not want to speak about the matter now or in the future" do  
  mark_outgoing_call 'To Player'
end

When "the user records that he spoke to the contact but he did not want to discuss the matter" do
  mark_call_status 'Call Connected'
  mark_next_step_status 'Complete'
  add_free_text_notes 'The player did not want to discuss the matter'
end


When "the contact answers the call and indicates he does not want to be called again" do
  true
end

Then "the user records that he spoke to the contact" do
  mark_call_status 'Call Connected'
end


Then "the user records that he does not want to be called again on any number" do
  mark_next_step_status 'Do Not Call Any Number'
  puts "TODO: need to handle tracker update for this"
end

When "the call connects and the user is informed not to call this number in the future" do
  mark_call_status 'Call Connected'

end

#TODO
Then "the user records this number to not be called in the future" do
  mark_next_step_status 'Do Not Call This Number'
  puts "TODO: need to handle tracker update for this and/or instructions to marking the phone number rank"
end

#TODO
When "the user is informed of an alternative number to call" do
  puts "TODO: add the new phone button to the phone list"
end

#TODO
Then "the user records this new number to be used as the primary number" do
  puts "TODO"
end

#TODO
Then "if appropriate the user records the current number to not be used in the future" do
  puts "TODO"
end

When "the contact answers the call and asks me to call back" do
  true
end


Then "the user records that a call-back was requested for a certain date and time" do
  mark_next_step_status 'Call Back', when: DateTime.now + 7.days

end

When "the call did not connect due to a bad number (does not exist, or does not belong to the contact)" do
  mark_outgoing_call 'To Player'

  mark_call_status 'Call Connected'
  mark_next_step_status 'Complete'  
end
Then "the user records that the number was a bad number" do
  
end
