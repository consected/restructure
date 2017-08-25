When "the contact answers a call from a user and they speak about the reason for the call" do
  mark_outgoing_call_answered 'by player'
  

end

Then "the user records that he spoke to the contact successfully about the matter" do
  mark_outgoing_call_status 'complete'
end