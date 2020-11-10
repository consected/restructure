module FullActivityLogAttrOptions

  def valid_call_detail_list(type)
    pi = PlayerInfo.all.last

    list = {
      user_outgoing: {
        phone_number: pi.master.player_contacts.last,
        select_call_direction: :to_player,
        select_who: 'user',
        called_when: DateTime.now,
        select_result: 'connected',
        select_next_step: 'completed'
      }
    }

    list[type]
  end
    
end
