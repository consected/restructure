module PhoneLogSupport
  include MasterSupport

  def list_valid_attribs
    [
      {
        select_call_direction: 'to player',
        select_who: 'user',
        called_when: DateTime.now - rand(100).days,
        select_result: 'connected',
        select_next_step: 'complete'
      },
      {
        select_call_direction: 'from player',
        select_who: 'user',
        called_when: DateTime.now - rand(100).days,
        select_result: 'connected',
        select_next_step: 'complete'
      },
      {
        select_call_direction: 'to player',
        select_who: 'user',
        called_when: DateTime.now - rand(100).days,
        select_result: 'voicemail',
        select_next_step: 'call back',
        follow_up_when: DateTime.now + rand(10).days
      }
    ]
  end
  def list_invalid_attribs
  end
  def new_attribs

  end
  def create_item  att=nil, player_contact=nil
    att ||= valid_attribs
    # add in the real phone number
    att[:data] = player_contact.data
    att[:master] = player_contact.master

    @log_item = player_contact.activity_log__player_contact_phones.create! att
  end

  def create_phone_logs player_contact, num=1
    num.times do
      res = create_item nil, player_contact
      raise "failed to create log item" unless res
    end
  end

end
