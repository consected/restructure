
module LogCallSetup



  def mark_outgoing_call to_who, opt={}

    opt[:from] ||= 'Me'
    opt[:called_when] ||= DateTime.now

    if opt[:called_when].is_a? Date
      opt[:called_when] = opt[:called_when].strftime('%m/%d/%Y')
    end
    
    res = have_css phone_log_block_css
    if !res
      puts "Can't find the form! #{phone_log_block_css}"
      sleep 10
      expect(res).to be true
    end

    within phone_log_block_css do
      select to_who, from: 'Select call direction'
      select opt[:from], from: 'Select who'
      fill_in 'Called when', with: opt[:called_when]
    end

  end

  def mark_call_status as
    within phone_log_block_css do
      select as, from: 'Select result'
    end
  end

  def mark_next_step_status as, opt={}

    within phone_log_block_css do
      select as, from: 'Select next step'
      if opt[:when]
        if opt[:when].is_a? Date
          opt[:when] = opt[:when].strftime('%m/%d/%Y')
        end
        fill_in "Follow up when", with: opt[:when]
      end
    end
  end



  def phone_log_block_css    
    PhoneList::NewPhoneLogFormCss
  end
end

World(LogCallSetup)