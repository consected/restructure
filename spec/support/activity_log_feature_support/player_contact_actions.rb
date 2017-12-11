module PlayerContactActions


  #Given "the user is viewing the contact's record in Zeus" do
  def user_views_contact_record

    user_logs_in
    # select a player, then check it appears in the results
    @player = select_player
    @master = @player.master

    expect(page).to have_css("#master-#{@player.master_id}")
    expect(find("#master-#{@player.master_id} .player-names").text).to eq("#{@player.first_name.capitalize} #{"#{@player.middle_name.capitalize} " unless @player.middle_name.blank?}#{@player.last_name.capitalize}#{" (#{@player.nick_name.capitalize})" unless @player.nick_name.blank?}")


    # click the result, if necessary
    if all('.master-result').length > 1
      find("#master-#{@player.master_id}").click
    end

    # expect the block to have expanded => the user is viewing the contact's record

    dismiss_modal
    finish_form_formatting


    expect(page).to have_css("#master-#{@player.master_id}-player-infos.collapse.in")
    expect(page).not_to have_css(".collapse.collapsing")


    finish_form_formatting
    dismiss_modal

  end

  #Given "the contact has one or more phone number records" do
  def expect_contact_to_have_a_phone_number
    res = top_ranked_phone

    expect(res).not_to be nil
  end


end
