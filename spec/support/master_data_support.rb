module MasterDataSupport
  include MasterSupport


  def list_length
    10
  end

  def full_master_number
    @full_master_number ||= rand(list_length)
  end

  def player_list
    res = []

    (1..list_length).each do |l|
      bd = (DateTime.now - (rand(50)+30).years)
      bd = opt(bd)

      dd = nil
      start_year = nil
      if bd
        dd = opt(DateTime.now - (rand(10).years) )
        start_year = opt(rand(6)+bd.year+19)
      end


      rank = get_a_rank
      rank = 881 unless bd




      res << {
        first_name: pick_from(first_names).downcase,
        last_name: pick_from(last_names).downcase,
        middle_name: pick_from(first_names).downcase,
        nick_name: pick_from(other_names).downcase,
        birth_date: bd,
        death_date: dd,
        rank: rank,
        start_year: start_year,
        college: pick_from(colleges).downcase,
        source: 'nflpa',
        end_year: opt(start_year ? start_year + rand(2) : nil),
        notes: 'kjsad hfkshfk jskjfhksajdhf sadf js dfjk sdkjf sdkjf\njg fjdhsag fjsahdg jsgadfjgsajdfgsf gsgf sdgj sa fj'
      }
    end

    res
  end

  def pro_list
    res = []

    (1..list_length).each do |l|
      bd = (DateTime.now - (rand(50)+20).years)
      bd = opt(bd)

      dd = nil
      if bd
        dd = opt(DateTime.now - (rand(10).years) )
      end

      start_year = opt(rand(10)+1980)

      res << {
        first_name: pick_from(first_names).downcase,
        last_name: pick_from(last_names).downcase,
        middle_name: pick_from(first_names).downcase,
        nick_name: pick_from(other_names).downcase,
        birth_date: bd,
        death_date: dd,
        start_year: start_year,
        college: pick_from(colleges).downcase,
        end_year: opt(start_year ? start_year + rand(12) : nil),
        pro_id: rand(100000)
      }
    end

    res
  end

  def get_a_rank
    ranks =  Classification::AccuracyScore.all
    ranks[rand(ranks.length)].value
  end

  def create_player_info att=nil, master=nil
    master ||= create_master
    setup_access :player_infos
    @player_info = master.player_infos.create! att
  end
  def create_pro_info att=nil, master=nil
    master ||= create_master
    setup_access :pro_infos
    @pro_info = master.pro_infos.create! att
  end


  def create_data_set options={}

    # Count the number of master records created
    @master_count = 0

    # Start the user number embedded in the email address at a random number
    @user_start = rand 1000000000
    reference_list_item = nil
    reference_pro_item = nil
    ActiveRecord::Base.connection.execute "update player_infos set rank = 11 where rank = 12;"



    player_list.each do |l|
      # Create a user with a specific number embedded
      create_user(@master_count+@user_start, "mds1")

      #Create a master and use the created user as the current user
      @master = Master.new
      @master.current_user = @user
      @master.save!

      # Generate a player_info and pro_info record
      # Player info is the current iteration
      # Pro info is the corresponding item in the pro list
      # Create both against the current master record

      p = pro_list[@master_count]


      # If the current item matches the predefined number, remember the
      # current @master record so that we can refer to it again
      # in the tests
      if @master_count == full_master_number
        reference_list_item = l
        reference_pro_item = p

        # Ensure the result always appears at the top of the list based on default accuracy score search
        l[:rank] = 12

        # Ensure start and end year tests can actually run
        l[:birth_date] ||= (DateTime.now - (rand(50)+40).years)
        l[:death_date] ||= (DateTime.now - (rand(10).years) )
        l[:start_year] ||= l[:birth_date].year + rand(9)+ 20
        l[:end_year] ||= l[:start_year] + rand(2)


        p[:birth_date] ||= (DateTime.now - (rand(50)+40).years)
        p[:death_date] ||= (DateTime.now - (rand(10).years) )
        p[:start_year] ||= p[:birth_date].year + rand(9)+ 20
        p[:end_year] ||= p[:start_year] + rand(2)
        p[:pro_id] = rand(100000)

        create_trackers @master unless options[:no_trackers]

        @full_player_info = create_player_info l, @master
        @full_pro_info = create_pro_info p, @master
        @full_master_record = @master.reload
        @full_trackers = @master.trackers.reload



      else
        # Ensure only the reference record has a rank that is 12
        if l[:rank] == 12
          l[:rank] = -1
        end
        create_player_info l, @master
        create_pro_info p, @master

        create_trackers @master unless options[:no_trackers]
      end

      @master_count += 1
    end

    # Create an additional item that can be guaranteed to match the reference item on certain searches, with a lower rank
    l = reference_list_item.dup
    p = reference_pro_item.dup
    @master = Master.new
    @master.current_user = @user
    @master.save!
    l[:rank] = 10
    l[:birth_date] = (l[:birth_date] || DateTime.now - 20.years) - 1.years
    p[:birth_date] = (p[:birth_date] || DateTime.now - 20.years) - 1.years
    create_player_info l, @master
    create_pro_info p, @master
    @master_count += 1

    # Create master records with player info only
    create_user
    @master = Master.new
    @master.current_user = @user
    @master.save!
    player_list.each do |li|
      if li[:rank] == 12
        li[:rank] = 9
      end

      li[:rank] = Classification::AccuracyScore.enabled.last unless Classification::AccuracyScore.enabled.include?(li[:rank])
      create_player_info li
      @master_count += 1
    end

    # Create master records with pro info only
    create_user
    @master = Master.new
    @master.current_user = @user
    @master.save!
    pro_list.each do |li|
      create_pro_info li
      @master_count += 1
    end


  end

  def create_trackers master
    (1..rand(5)).each do
      Classification::Protocol.selectable.each do |pr|

        sps = pr.sub_processes.enabled
        sp = pick_one_from sps


        pes = sp.protocol_events.enabled
        pe = pick_one_from pes

        t = master.trackers.build protocol: pr, sub_process: sp, protocol_event: pe, event_date: DateTime.now - 1.year
        t.merge_if_exists! rescue nil

      end
    end
  end

  def master_error res, params=nil
    "Expected master #{@full_master_record.inspect}, with #{@full_player_info.inspect} and #{@full_pro_info.inspect}\nGot #{res.first ? res.first.player_infos.first.inspect : nil}.\nParams: #{params}"
  end

end
