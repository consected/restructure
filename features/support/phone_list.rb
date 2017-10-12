module PhoneList

  PhoneLogList = '.activity-log-sub-list'
  PhoneItemsCss = '.sub-list-item.phone-type'
  SelectedPhoneItemCss = "#{PhoneItemsCss}.selected-item"
  PhoneItemNumberCss = 'a[data-rec-type="phone"]'
  SelectedPhoneNumberCss = "#{SelectedPhoneItemCss} #{PhoneItemNumberCss}"
  LogPhoneCallButtonCss = '.activity-log-initial-action a.btn'
  NewPhoneLogFormCss = 'form#new_activity_log__player_contact_phone'
  PhoneLogBlockCss ='.activity-logs-player-contact-phone-type-block.in'

  def expect_phone_log_to_show_contact_number
    finish_form_formatting
    expect(page).to have_css(SelectedPhoneNumberCss)
    expect(find(SelectedPhoneNumberCss).text).to eq(@player_phone_num)
  end

  def phone_log_block
    finish_form_formatting
    have_css(PhoneLogBlockCss)
    find(PhoneLogBlockCss)
  end

  def phone_log_phone_list
    finish_form_formatting
    phone_log_block.find(PhoneLogList)
  end

  def phone_item num
    finish_form_formatting
    have_css(PhoneItemsCss)
    phone_log_phone_list.all(PhoneItemsCss)[num]
  end

  def check_phone_log_phone_list
    finish_form_formatting
    expect(phone_log_phone_list).to have_css(PhoneItemsCss)
  end

  def select_phone_to_call
    within phone_item(0) do
      find(PhoneItemNumberCss).click
    end
    finish_form_formatting

    expect(page).to have_css(SelectedPhoneItemCss)

    within phone_item(0) do
      expect(page).to have_css(LogPhoneCallButtonCss)
      click_link 'log phone call'
    end

    expect(page).to have_css(NewPhoneLogFormCss)
  end

  def selected_phone_number
    sel_phone = find(SelectedPhoneItemCss)
    expect(sel_phone['class'].include?('selected-item')).to be true
    di = sel_phone.find('[data-rec-type="phone"]')
    phone = di['data-item-data']
    diid = sel_phone['data-sub-id']
    puts "Selected phone number in list: #{phone} (#{diid})"

    phone
  end
end

World(PhoneList)
