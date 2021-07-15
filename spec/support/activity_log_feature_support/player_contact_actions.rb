module PlayerContactActions
  # Given "the user is viewing the contact's record in Zeus" do
  def user_views_contact_record
    user_logs_in

    has_css?('#simple_search_master.form-formatted')

    # select a player, then check it appears in the results
    @player = select_player
    @master = @player.master

    unless has_css?("#master-#{@player.master_id}")
      p = PlayerInfo.where(first_name: @player.first_name, last_name: @player.last_name).first
      puts "Player #{@player.master_id} not shown for #{@player.attributes}. In DB: #{p&.attributes}"

    end
    expect(page).to have_css("#master-#{@player.master_id}")
    expect(find("#master-#{@player.master_id} .player-names").text).to eq("#{@player.first_name.capitalize} #{@player.middle_name.blank? ? '' : "#{@player.middle_name.capitalize} "}#{@player.last_name.capitalize}#{@player.nick_name.blank? ? '' : " (#{@player.nick_name.capitalize})"}")

    # click the result, if necessary
    find("#master-#{@player.master_id}").click if all('.master-result').length > 1

    # expect the block to have expanded => the user is viewing the contact's record

    dismiss_modal
    finish_form_formatting

    expect_master_to_have_expanded @player.master_id

    finish_form_formatting
    dismiss_modal
  end

  # Given "the contact has one or more phone number records" do
  def expect_contact_to_have_a_phone_number
    res = top_ranked_phone

    expect(res).not_to be nil
  end
end
