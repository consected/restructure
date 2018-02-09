require "rails_helper"
require "benchmark"

RSpec.describe "Performance", type: :model do
  include ModelSupport

  NumProtocols = 10
  NumMasters = 100
  NumTrackerItems = 100


  def create_trackers_for master, num=NumTrackerItems
    @trackers = []
    (1..NumProtocols).each do |i|
      p1 = Protocol.active.where(name: "PerfP1 #{i}").first
      sp1_1 = p1.sub_processes.active.where(name: "SP1 #{i}").first
      pe1 = sp1_1.protocol_events.first
      num.times do
        @trackers << master.trackers.create(protocol_id: p1.id, sub_process_id: sp1_1.id, event_date: DateTime.now)
      end
    end
  end

  def create_trackers_for_all_types_for master
     Protocol.active.each do |p|
       p.sub_processes.active.each do |sp|
         active_sp = sp.protocol_events.active
         if active_sp.length > 0
           active_sp.each do |pe|
             master.trackers.create(protocol_id: p.id, sub_process_id: sp.id, protocol_event_id: pe.id, event_date: DateTime.now)
           end
         else
           master.trackers.create(protocol_id: p.id, sub_process_id: sp.id, event_date: DateTime.now)
         end
       end
    end
  end

  before(:each) do

    create_user
    create_admin

    @masters = []

    (1..NumProtocols).each do |i|
      @p1 = Protocol.create name: "PerfP1 #{i}", current_admin: @admin
      @p2 = Protocol.create name: "PerfP2 #{i}", current_admin: @admin

      @sp1_1 = @p1.sub_processes.create name: "SP1 #{i}", current_admin: @admin
      @sp1_2 = @p1.sub_processes.create name: "SP12 #{i}", current_admin: @admin
      @sp2_1 = @p2.sub_processes.create name: "SP2 #{i}", current_admin: @admin
    end

    (1..NumMasters).each do
      @master = Master.new
      @master.current_user = @user
      @master.save!
      @masters << @master
    end

  end

  it "Creates #{NumTrackerItems} tracker items for a master and checks the performance to retrieve them" do

    create_trackers_for @master

    # Load all items individually
    user = User.find(@user.id)
    master = Master.find(@master.id)
    master.current_user = @user
    th = nil
    th_length = 0

    # First, do this the brute force way
    Rails.logger.debug "****************** Loading tracker  without preload optimizations *********************"
    t = Benchmark.realtime do
      th = Tracker.where(master_id: master.id).all
      th_length = th.length
    end

    puts "Tracker time: #{t}"

    expect(th_length).to be <= NumProtocols
    expect(t).to be < 0.5


    # Now repeat with the same approach as used in a controller
    Rails.logger.debug "********************* Loading trackers  with preload optimizations *********************"
    t = Benchmark.realtime do
      th = master.trackers.all
      th_length = th.length
    end

    puts "Tracker time: #{t}"
    puts "Tracker length: #{th.count}"
    expect(th_length).to be <= NumProtocols
    expect(t).to be < 0.5

    # Now convert to JSON
    Rails.logger.debug "********************* Converting tracker  to JSON with preload optimizations *********************"
    jt = nil
    t = Benchmark.realtime do
      jt = {trackers: th.as_json(current_user: @user), multiple_results: 'trackers'}.to_json(current_user: @user)
    end

    puts "Trackers JSON time: #{t}"
    expect(t).to be < 2.0

    expect(JSON.parse(jt)["trackers"].length).to be <= NumProtocols

  end



  it "Creates #{NumTrackerItems} tracker history items for a master and checks the performance to retrieve them" do

    create_trackers_for @master

    # Load all items individually
    user = User.find(@user.id)
    master = Master.find(@master.id)
    master.current_user = @user

    th = nil
    th_length = 0

    # First, do this the brute force way
    Rails.logger.debug "****************** Loading tracker histories without preload optimizations *********************"
    t = Benchmark.realtime do
      th = TrackerHistory.where(master_id: master.id).order(Master::TrackerHistoryEventOrderClause).all
      th_length = th.length
    end

    puts "TrackerHistory time: #{t}"

    expect(th_length).to be >= NumTrackerItems
    expect(t).to be < 0.5


    # Now repeat with the same approach as used in a controller
    Rails.logger.debug "********************* Loading trackers histories with preload optimizations *********************"
    t = Benchmark.realtime do
      th = master.tracker_histories.all
      th_length = th.length
    end

    puts "TrackerHistory time: #{t}"
    puts "TrackerHistory length: #{th.length}"
    expect(th_length).to be >= NumTrackerItems
    expect(t).to be < 0.5

    # Now convert to JSON
    Rails.logger.debug "********************* Converting tracker histories to JSON with preload optimizations *********************"
    jt = nil
    t = Benchmark.realtime do
      jt = {tracker_histories: th, master_id: master.id}.to_json(current_user: @user)
    end

    puts "TrackerHistory JSON time: #{t}"
    expect(t).to be < 3.0

    expect(JSON.parse(jt)["tracker_histories"].length).to be >= NumTrackerItems

  end




  it "Creates tracker history items for each master and checks the performance encode the #{NumMasters} masters" do

    puts "Creating tracker items for Masters"
    @masters.each do |master|
      create_trackers_for_all_types_for master
    end

    puts "Benchmarking tracker items for Masters"
    user = User.find(@user.id)
    master = Master.find(@master.id)
    master.current_user = @masters.first.user

    jt = nil
    t = Benchmark.realtime do
      jt = {
          masters: @masters.as_json(current_user: @user),
          count: {
            count: 0,
            show_count: @masters.length
          },
          search_action: 'Test',
          message: 'OK'
        }.to_json
    end

    puts "Masters JSON time: #{t}"
    expect(t).to be < 3.0

    expect(JSON.parse(jt)["masters"].length).to be >= NumMasters

    expect(JSON.parse(jt)["masters"][(NumMasters/2).to_i]["latest_tracker_history"].length).to be == 1

  end



end
