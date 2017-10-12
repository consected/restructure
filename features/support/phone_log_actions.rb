module PhoneLogActions

  ActivityLogListBlockCss = ".activity-logs-player-contact-phone-type-block .activity-log-list"
  LoggedPhoneCallCss = "#{ActivityLogListBlockCss} .activity-log--player-contact-phone-item"
  PhoneNumberInItemCss = ".activity-log--player-contact-phone-data strong"



  def expect_phone_log_to_highlight_selected_phone_number
    expect_phone_log_to_be_visible

    phone = selected_phone_number

    all(LoggedPhoneCallCss).each do |e|
      scroll_to(LoggedPhoneCallCss)
      p = e.find(PhoneNumberInItemCss).text
      puts "Got phone number from block: #{p}"
      selected = e['class'].include?('selected-item')
      puts "Block selected? #{selected} with '#{e['class']}' in #{LoggedPhoneCallCss} with #{e['data-item-id']}"
      if p == phone
        if !selected
          sleep 10
        end
        expect(selected).to be true
      else
        if selected
          sleep 10
        end
        expect(selected).to be false
      end
    end

  end

  def expect_phone_log_to_be_visible
    finish_form_formatting
    expect(page).to have_css(ActivityLogListBlockCss)
    if all("#{ActivityLogListBlockCss} .new-block h4").length == 0
      expect(page).to have_css(LoggedPhoneCallCss)
    end

  end

end
World(PhoneLogActions)
