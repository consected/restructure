module ItemFlagSupport
  include MasterSupport

  def create_item_flag_name item_type
    ifn = ItemFlagName.create! name: "IFN #{Time.new.to_f} #{rand 1000000000}", current_admin: @admin, item_type: item_type
    @item_flag_name = ifn
  end

  def list_valid_attribs

    create_item_flag_name 'player_info'

    @player_info = PlayerInfo.last

    if @player_info && @player_info.master
      @player_info.master.current_user = @user
    else
      @player_info = nil
    end

    unless @player_info
      master = create_master
      master.current_user = @user

      pi = master.player_infos.create!(
      {
        first_name: 'test',
        last_name: 'test',
        birth_date: Date.today - 40.years,

        rank: 10,
        source: 'nflpa'
      }
      )
      @player_info = pi
    end

    raise "failed to set master user" unless @player_info.master_user


    [
      {
        item_id: @player_info.id,
        item_type: 'player_info',
        item_flag_name_id: @item_flag_name.id
      }
    ]


  end

  def list_invalid_attribs
    create_master
    create_item
    create_item_flag_name 'player_info'
    [
      {
        master_id: @player_info.master_id,
        item_controller: 'player_infos',
        item_id: @player_info.id,
        item_flag: {
          item_flag_name_id: [-4]
        }
      }


    ]
  end

  def list_invalid_update_attribs
    [

      {
        item_type: 'PlayerInfo'
      }
    ]
  end

  def new_attribs
    create_item
    @new_attribs = {
        item_id: @player_info.id,
        item_type: 'player_info',
        item_flag_name_id: @item_flag_name.id
      }
  end



  def create_item att=nil, item=nil
    att ||= valid_attribs

    item ||= @player_info

    raise "failed to set master user in player info" unless item.master_user


    @item_flag = item.item_flags.create! att

    # send to master_user, since it is protected and therefore inaccessible
    raise "failed to set master user in parent" unless @item_flag.send(:master_user)
    @item_flag
  end

end
