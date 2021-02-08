module PhoneLogSupport
  include MasterSupport

  def list_valid_attribs
    [
      {
        select_call_direction: 'to player',
        select_who: 'user',
        called_when: DateTime.now - rand(100).days,
        select_result: 'connected',
        select_next_step: 'complete',
        extra_log_type: 'primary'
      },
      {
        select_call_direction: 'to staff',
        select_who: 'user',
        called_when: DateTime.now - rand(100).days,
        select_result: 'connected',
        select_next_step: 'complete',
        extra_log_type: 'primary'
      },
      {
        select_call_direction: 'to player',
        select_who: 'user',
        called_when: DateTime.now - rand(100).days,
        select_result: 'voicemail',
        select_next_step: 'call back',
        follow_up_when: DateTime.now + rand(10).days,
        extra_log_type: 'primary'
      }
    ]
  end

  def list_invalid_attribs; end

  def new_attribs; end

  def create_item(att = nil, player_contact = nil)
    att ||= valid_attribs
    # add in the real phone number
    att[:data] = player_contact.data
    att[:master] = player_contact.master

    @log_item = player_contact.activity_log__player_contact_phones.create! att
  end

  def create_phone_logs(player_contact, num = 1)
    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create,
                                                       user: player_contact.current_user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create,
                                                               user: player_contact.current_user

    num.times do
      res = create_item nil, player_contact
      raise 'failed to create log item' unless res
    end
  end
end
