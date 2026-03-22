# frozen_string_literal: true

module MasterDataSupport
  include MasterSupport

  def list_length
    5
  end

  def full_master_number
    @full_master_number ||= rand(list_length)
  end

  def player_list
    return @player_list if @player_list

    res = []

    (1..list_length).each do |_l|
      bd = (DateTime.now - rand(30..79).years)
      bd = opt(bd)

      dd = nil
      start_year = nil
      if bd
        dd = opt(DateTime.now - rand(10).years)
        start_year = opt(rand(6) + bd.year + 19)
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
        rank:,
        start_year:,
        college: pick_from(colleges).downcase,
        source: 'nflpa',
        end_year: opt(start_year ? start_year + rand(2) : nil),
        notes: 'kjsad hfkshfk jskjfhksajdhf sadf js dfjk sdkjf sdkjf\njg fjdhsag fjsahdg jsgadfjgsajdfgsf gsgf sdgj sa fj'
      }
    end

    @player_list = res
  end

  def pro_list
    return @pro_list if @pro_list

    res = []

    (1..list_length).each do |_l|
      bd = (DateTime.now - rand(20..69).years)
      bd = opt(bd)

      dd = nil
      dd = opt(DateTime.now - rand(10).years) if bd

      start_year = opt(rand(1980..1989))

      res << {
        first_name: pick_from(first_names).downcase,
        last_name: pick_from(last_names).downcase,
        middle_name: pick_from(first_names).downcase,
        nick_name: pick_from(other_names).downcase,
        birth_date: bd,
        death_date: dd,
        start_year:,
        college: pick_from(colleges).downcase,
        end_year: opt(start_year ? start_year + rand(12) : nil),
        pro_id: rand(100_000)
      }
    end

    @pro_list = res
  end

  def get_a_rank
    ranks = Classification::AccuracyScore.all
    ranks[rand(ranks.length)].value
  end

  def create_player_info(att = nil, master = nil)
    master ||= create_master
    setup_access :player_infos
    create_sources 'player_infos'
    @player_info = master.player_infos.create! att
  end

  def create_pro_info(att = nil, master = nil)
    master ||= create_master
    setup_access :pro_infos
    @pro_info = master.pro_infos.create! att
  end

  # Force a new connection (with a thread) to create the data set
  # This is necessary for features to recognize the new changes,
  # but has the side effect of leaving the database with data
  # after each run
  def create_data_set_outside_tx(no_trackers: false, no_seed: false)
    # Check if data set has already been created in this test run
    # Use a cache key that includes the options to ensure different configurations are handled separately
    cache_key = "data_set_#{no_trackers}_#{no_seed}"
    if SetupHelper.spec_tally_done?(cache_key)
      Rails.logger.info '** Data set already created, skipping **'
      puts '** Data set already created, skipping **'

      # Still need to set up instance variables that specs expect
      # Find the reference master by looking for the player_info with rank=12,
      # which is uniquely set during create_data_set for the reference record
      ref_pi = PlayerInfo.find_by(rank: 12)
      @master = ref_pi&.master || Master.no_temporary_masters.first
      @master_id = @master&.id
      @full_player_info = ref_pi || @master.player_infos.first
      @full_pro_info = @master.pro_infos.first
      @full_master_record = @master
      @full_trackers = @master.trackers.reload
      @app_type = Admin::AppType.active.first
      @user_start = rand 1_000_000_000
      @master_count = [Master.count, list_length].min
      return
    end

    t0 = Time.now
    Rails.logger.info '** Creating data set outside transaction **'
    puts "#{t0} ** Creating data set outside transaction **"
    t1 = nil
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        if no_seed
          puts '**   No seeds specified **'
          t1 = t0 # Set t1 to t0 when skipping seeds
        else
          seed_database
          t1 = Time.now
          puts "**   Ran seeds in #{t1 - t0} seconds **"
        end
        create_data_set no_trackers:, no_seed: true
      end
    end.join
    t2 = Time.now
    puts "**   Ran create_data_set in #{t2 - t1} seconds **"
    puts "** Created data set outside transaction in #{t2 - t0} seconds **"
    Rails.logger.info "** Created data set outside transaction in #{t2 - t0} seconds **"

    # Mark this data set as created
    SetupHelper.add_to_spec_db(cache_key)
    @create_data_set_outside_tx_done = true
  end

  def create_data_set(no_trackers: false, no_seed: false)
    return if @create_data_set_done

    # Count the number of master records created
    @master_count = 0

    # Check trackers will work
    seed_database unless no_seed
    expect(Classification::ProtocolEvent.active.reload.find_by(name: 'created player info')).not_to be nil
    expect(Classification::ProtocolEvent.active.reload.find_by(name: 'updated player info')).not_to be nil

    # Start the user number embedded in the email address at a random number
    @user_start = rand 1_000_000_000
    reference_list_item = nil
    reference_pro_item = nil
    ActiveRecord::Base.connection.execute 'update player_infos set rank = 11 where rank = 12;'

    @app_type = Admin::AppType.active.first

    prol = pro_list.first(list_length)
    pl = player_list.first(list_length)
    pl.each do |l|
      # Create a user with a specific number embedded
      create_user(@master_count + @user_start, 'mds1')
      @user.app_type = @app_type
      setup_access :trackers
      setup_access :player_infos

      # Create a master and use the created user as the current user
      @master = Master.new
      @master.current_user = @user
      @master.save!

      # Generate a player_info and pro_info record
      # Player info is the current iteration
      # Pro info is the corresponding item in the pro list
      # Create both against the current master record
      p = prol[@master_count]

      # If the current item matches the predefined number, remember the
      # current @master record so that we can refer to it again
      # in the tests
      if @master_count == full_master_number
        reference_list_item = l
        reference_pro_item = p

        # Ensure the result always appears at the top of the list based on default accuracy score search
        l[:rank] = 12

        # Ensure start and end year tests can actually run
        l[:birth_date] ||= (DateTime.now - rand(40..89).years)
        l[:death_date] ||= (DateTime.now - rand(10).years)
        l[:start_year] ||= l[:birth_date].year + rand(9) + 20
        l[:end_year] ||= l[:start_year] + rand(2)

        p[:birth_date] ||= (DateTime.now - rand(40..89).years)
        p[:death_date] ||= (DateTime.now - rand(10).years)
        p[:start_year] ||= p[:birth_date].year + rand(9) + 20
        p[:end_year] ||= p[:start_year] + rand(2)
        p[:pro_id] = rand(100_000)

        create_trackers @master unless no_trackers

        @full_player_info = create_player_info l, @master
        @full_pro_info = create_pro_info p, @master
        @full_master_record = @master.reload
        @full_trackers = @master.trackers.reload

      else
        # Ensure only the reference record has a rank that is 12
        l[:rank] = -1 if l[:rank] == 12
        create_player_info l, @master
        create_pro_info p, @master

        create_trackers @master unless no_trackers
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
    l[:birth_date] = (l[:birth_date] || (DateTime.now - 20.years)) - 1.years
    p[:birth_date] = (p[:birth_date] || (DateTime.now - 20.years)) - 1.years
    create_player_info l, @master
    create_pro_info p, @master
    @master_count += 1

    # Create master records with player info only
    create_user
    @master = Master.new
    @master.current_user = @user
    @master.save!
    pl.each do |li|
      li[:rank] = 9 if li[:rank] == 12

      unless Classification::AccuracyScore.enabled.include?(li[:rank])
        li[:rank] = Classification::AccuracyScore.enabled.last
      end
      create_player_info li
      @master_count += 1
    end

    # Create master records with pro info only
    create_user
    @master = Master.new
    @master.current_user = @user
    @master.save!
    prol.each do |li|
      create_pro_info li
      @master_count += 1
    end
  end

  def create_trackers(master)
    (1..rand(5)).each do
      Classification::Protocol.selectable.each do |pr|
        sps = pr.sub_processes.enabled
        sp = pick_one_from sps

        pes = sp.protocol_events.enabled
        pe = pick_one_from pes

        t = master.trackers.build protocol: pr, sub_process: sp, protocol_event: pe, event_date: DateTime.now - 1.year
        begin
          t.merge_if_exists!
        rescue StandardError
          nil
        end
      end
    end
  end

  def master_error(res, params = nil)
    "Expected master #{@full_master_record.inspect}, with #{@full_player_info.inspect} and #{@full_pro_info.inspect}\nGot #{if res.first
                                                                                                                              res.first.player_infos.first.inspect
                                                                                                                            end}.\nParams: #{params}"
  end
end
