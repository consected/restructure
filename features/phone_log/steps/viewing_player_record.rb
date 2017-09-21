
Before do
  setup_database
  create_phone_log_config
end

Given "the user has logged in" do
  user_login unless user_logged_in?
  expect(user_logged_in?).to be true
end


Given "the user is viewing the contact's record in Zeus" do

  steps %Q{
    Given the user has logged in
  }
  # select a player, then check it appears in the results
  @player = select_player
  @master = @player.master

  expect(page).to have_css("#master-#{@player.master_id}")
  expect(find("#master-#{@player.master_id} .player-names").text).to eq("#{@player.first_name.capitalize} #{@player.middle_name.capitalize} #{@player.last_name.capitalize} (#{@player.nick_name.capitalize})")


  # click the result, if necessary
  if all('.master-result').length > 1
    find("#master-#{@player.master_id}").click
  end

  dismiss_modal
  
  # expect the block to have expanded => the user is viewing the contact's record
  expect(page).to have_css("#master-#{@player.master_id}-player-infos.collapse.in")

  dismiss_modal
  
end

Given "the contact has one or more phone number records" do
  res = top_ranked_phone

  if res.nil?
    puts "Sleeping for 10 to see why the contact phone numbers are not showing"
    sleep 10
  end

  expect(res).not_to be nil

end