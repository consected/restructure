
Before do
  setup_database
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
  
  # expect the block to have expanded => the user is viewing the contact's record
  expect(page).to have_css("#master-#{@player.master_id}-player-infos.collapse.in")
  
end
