module ESignatureSupport
  include MasterSupport

  def gen_activity_log_path(master_id, item_id, id = nil)
    res = "/masters/#{master_id}/player_infos/#{item_id}/activity_log/player_info_e_signs"
    res += "/#{id}" if id
    res
  end

  def create_item(att = nil, item = nil, no_model_to_sign: nil)
    @model_to_sign = nil
    unless @player_info
      setup_access :player_infos

      @player_info = @master.player_infos.create!({
                                                    first_name: 'bob',
                                                    last_name: 'jones'
                                                  })
      @player_info = PlayerInfo.last
    end

    master ||= @master || @player_info.master
    master.current_user = @user

    item ||= @player_info

    elt = 'sign'
    elt = 'create_and_sign' if no_model_to_sign
    att = {
      player_info: item,
      master:,
      extra_log_type: elt
    }

    @activity_log = @player_info.activity_log__player_info_e_signs.create! att

    unless no_model_to_sign
      @model_to_sign = ::IpaInexChecklist.create!(
        ix_consent_blank_yes_no: 'yes',
        master:,
        fixed_checklist_type: 'test document'
      )

      ModelReference.create_with @activity_log, @model_to_sign
    end

    @activity_log
  end
end
