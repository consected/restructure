
module LogCallSetup


  def expect_phone_log_to_be_visible
    expect(page).to have_css(".activity-logs-player-contact-phone-type-block")
  end

  def expect_phone_log_to_show_contact_number
    css_phone_num = ".al-data-phone-num"
    expect(page).to have_css(css_phone_num)
    expect(find(css_phone_num).text).to eq(@player_phone_num)
  end

  def scroll_to_phone_log#
    page.execute_script "document.getElementById(\"activity-logs-#{@master.id}\").scrollTop += 100"
    expect(page).to have_selector("#activity-logs-#{@master.id}", visible: true)
  end

  def mark_outgoing_call_answered  to_who, from='me'

    click_link 'outgoing call'
    have_css phone_log_block_css
    within phone_log_block_css do
      select from, from: 'the call is from'
      select to_who, from: 'calling'
    end

  end

  def mark_outgoing_call_status as
    within phone_log_block_css do
      select as, from: 'with outcome'
    end
  end

  def phone_log_block_css master_id=nil
    master_id ||= @master.id
    "#player-contact-activity-logs-phone-type-#{master_id}"
  end
end

World(LogCallSetup)