module LogExpectations
  LogItemsCss = '.activity-log--player-contact-phone-primary-item'
  LogTrackerHistoriesCss = '.related-tracker-collapser.in .activity-log--player-contact-phone-primary-tracker-histories'
  LogTrackerHistoriesCaptionCss = '.activity-log--player-contact-phone-primary-tracker-histories-caption'
  ActivityLogListBlockCss = '.activity-log--player-contact-phones-block .activity-log-list'
  LoggedPhoneCallCss = "#{ActivityLogListBlockCss} .activity-log--player-contact-phone-primary-item"
  PhoneNumberInItemCss = '.activity-log--player-contact-phone-primary-data strong'

  def expect_phone_log_to_highlight_selected_phone_number
    expect_phone_log_to_be_visible

    phone = selected_phone_number

    all(LoggedPhoneCallCss).each do |e|
      scroll_to(LoggedPhoneCallCss)
      p = e.find(PhoneNumberInItemCss).text
      # puts "Got phone number from block: #{p}"
      selected = e['class'].include?('selected-item')
      # puts "Block selected? #{selected} with '#{e['class']}' in #{LoggedPhoneCallCss} with #{e['data-item-id']}"
      if p == phone
        expect(selected).to be true
      else
        expect(selected).to be false
      end
    end
  end

  def expect_phone_log_to_be_visible
    finish_form_formatting

    expect(page).to have_css(ActivityLogListBlockCss)
    expect(page).to have_css(LoggedPhoneCallCss) if all("#{ActivityLogListBlockCss} .new-block h4").length == 0
  end

  def expect_log_to_show(values)
    # allow build server tests to catch up
    sleep 1
    finish_form_formatting
    sleep 1
    finish_form_formatting

    have_css(LogItemsCss)
    log = all(LogItemsCss).first
    within log do
      values.each do |k, v|
        el = if k == :notes
               ".activity-log--player-contact-phone-primary-#{k} .notes-text"
             else
               ".activity-log--player-contact-phone-primary-#{k} strong"
             end
        expect(find(el).text.downcase).to eq v.downcase
      end
    end
  end

  def expect_log_player_contact_to(values)
    return unless values[:have_rank]

    have_css("#{PhoneListActions::PhoneItemsCss}.selected-item")
    rank_text = find("#{PhoneListActions::PhoneItemsCss}.selected-item span.label-info").text
    expect(rank_text).to eq values[:have_rank]
  end

  def expect_tracker_event_to_include(date, protocol, sp, pe = nil, index = 0)
    items = [protocol, sp]
    items << pe if pe
    etext = "#{date.strftime('%m/%d/%Y')} #{items.join(' / ')}"

    # Click the histories caption to expand
    histscap = all(LogTrackerHistoriesCaptionCss)[index]
    histscap.click

    has_css?(LogTrackerHistoriesCss)

    hists = all(LogTrackerHistoriesCss)[index + 1]

    res = hists.find('.small')
    expect(res.text).to eq etext
  end
end
