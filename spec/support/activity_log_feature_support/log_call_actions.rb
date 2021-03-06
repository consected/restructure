
module LogCallActions


  #When "the user indicates that he has received a call" do
  def indicate_user_received_a_call

    show_top_ranked_phone_log
    select_phone_to_receive_call_from
    mark_call_activity ActivityLogMain::CallToStaff

  end

  def indicate_user_made_a_call

    show_top_ranked_phone_log
    select_phone_to_call
    mark_call_activity ActivityLogMain::CallToPlayer

  end

  def mark_call_activity to_who, opt={}

    opt[:from] ||= 'User'
    opt[:called_when] ||= DateTime.now

    if opt[:called_when].is_a? Date
      opt[:called_when] = opt[:called_when].strftime('%m/%d/%Y')
    end

    res = have_css phone_log_block_css
    if !res
      puts "Can't find the form! #{phone_log_block_css}"
      expect(res).to be true
    end

    within phone_log_block_css do
      select to_who, from: 'Select call direction'
      select opt[:from], from: 'Select who'
      fill_in 'Called when', with: opt[:called_when]
      close_datepicker
    end

  end


  def mark_call_status as
    close_datepicker
    within phone_log_block_css do
      select as, from: 'Select result'
    end
  end

  def close_datepicker
    # Ensure the datepicker is not open
    dpc = all('.al-label-player-contact-phone-item')
    dpc.each {|e| e.click}
    sleep 0.5
  end

  def mark_next_step_status as, opt={}

    within phone_log_block_css do
      select as, from: 'Select next step'
      if opt[:when]
        f = find('#activity_log_player_contact_phone_follow_up_when')
        if opt[:when].is_a? Date
          if f[:type] == 'date'
            opt[:when] = opt[:when].strftime('%Y-%m-%d')
            # We have to cheat to get Firefox 57 to accept dates
            f.send_keys opt[:when]
            close_datepicker
          else
            opt[:when] = opt[:when].strftime('%m\/%d\/%Y')
            fill_in "Follow up when", with: opt[:when]
            close_datepicker
          end
        end
      end
    end
  end


  def add_free_text_notes text
    within phone_log_block_css do
      fill_in 'Notes', with: text
    end
  end

  def set_related_player_contact_rank rank
    within phone_log_block_css do

      select rank, from: 'activity_log_player_contact_phone_set_related_player_contact_rank'
    end
  end

  def select_related_protocol protocol
    within phone_log_block_css do
      select protocol, from: 'activity_log_player_contact_phone_protocol_id'
    end
  end


  def save_log
    within phone_log_block_css do
      click_button 'Save'
    end
  end

  def phone_log_block_css
    PhoneListActions::NewPhoneLogFormCss
  end
end
