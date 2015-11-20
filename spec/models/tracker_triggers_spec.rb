require 'rails_helper'

# Spec for trackers and tracker_history triggers in the database
# Used to test direct execution of SQL queries against the database, as performed by DBA and Data Manager roles

RSpec.describe Tracker, type: :model do
  include ModelSupport
  
  def execute sql
    Tracker.connection.execute sql
    
  end
  
  before(:each) do
    
    create_user
    create_admin
    @p1 = Protocol.create name: 'P1-trig', current_admin: @admin
    @p2 = Protocol.create name: 'P2-trig', current_admin: @admin
    
    @sp1_1 = @p1.sub_processes.create name: 'SP1-trig', current_admin: @admin
    @sp1_2 = @p1.sub_processes.create name: 'SP12-trig', current_admin: @admin
    @sp1_3 = @p1.sub_processes.create name: 'SP13-trig', current_admin: @admin
    @sp2_1 = @p2.sub_processes.create name: 'SP2-trig', current_admin: @admin
    @sp2_2 = @p2.sub_processes.create name: 'SP22-trig', current_admin: @admin
        
    @master = Master.new    
    @master.current_user = @user
    @master.save!
     
    @user_id = @user.id
  end
  
  
  it "allows trackers to be created for a master" do
    res = execute "
      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p1.id}, #{@sp1_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

      select * from trackers where master_id = #{@master.id};
    " 

    
    
    expect(res.count).to eq 1
        
    expect(res.first['protocol_id']).to eq @p1.id.to_s
    
    res = execute "select * from tracker_history where master_id = #{@master.id} and protocol_id = #{@p1.id};"
    expect(res.count).to eq 1
  end
      
  it "updates existing tracker record if attempting to insert with same protocol" do
    
    res = execute "
      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p1.id}, #{@sp1_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});


      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p1.id}, #{@sp1_2.id}, '#{DateTime.now}', now(), now(), #{@user_id});
      select * from trackers where master_id = #{@master.id};
    " 

    
    expect(res.count).to eq 1
    expect(res.first['protocol_id']).to eq @p1.id.to_s
    
    res = execute "select * from tracker_history where master_id = #{@master.id} and protocol_id = #{@p1.id};"
    expect(res.count).to eq 2
  end
  
  it "does not update existing tracker record if attempting to insert with same protocol but the event date is earlier" do
    
    res = execute "
      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p1.id}, #{@sp1_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p1.id}, #{@sp1_2.id}, '#{DateTime.now}', now(), now(), #{@user_id});

      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p1.id}, #{@sp1_3.id}, '#{DateTime.now - 1.day}', now(), now(), #{@user_id});
      select * from trackers where master_id = #{@master.id};
    " 

    t = res.first
    expect(res.count).to eq 1
    expect(t['protocol_id']).to eq @p1.id.to_s
    expect(t['sub_process_id']).to eq @sp1_2.id.to_s # the tracker record should still match the previous sub process
    
    res = execute "select * from tracker_history where master_id = #{@master.id} and protocol_id = #{@p1.id};"
    expect(res.count).to eq 3
    
  end
  
  it "allows tracker to be created for a master with new protocol" do
    res = execute "
      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});
      select * from trackers where master_id = #{@master.id} and protocol_id = #{@p2.id};
    " 

    
    expect(res.count).to eq 1
        
    t = res.first
    expect(t['sub_process_id']).to eq @sp2_1.id.to_s
    
    res = execute "select * from tracker_history where master_id = #{@master.id} and protocol_id = #{@p2.id};"
    expect(res.count).to eq 1
    
  end
  
  it "removes the tracker item when the only tracker_history item is removed" do
    res = execute "
      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

      delete from tracker_history where 
      master_id = #{@master.id} and protocol_id = #{@p2.id};
      
      select * from trackers where master_id = #{@master.id} and protocol_id = #{@p2.id};
    " 
    
    expect(res.count).to eq 0
        
    res = execute "select * from tracker_history where master_id = #{@master.id} and protocol_id = #{@p2.id};"
    
    expect(res.count).to eq 0
    
  end
  
  it "does not update the tracker item when an older tracker_history item is removed" do

    res = execute "select * from tracker_history where master_id = #{@master.id} and protocol_id = #{@p2.id};"

    expect(res.count).to eq 0

    sql = "
      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{DateTime.now - 1.day}', now(), now(), #{@user_id});

      delete from tracker_history where 
      master_id = #{@master.id} and protocol_id = #{@p2.id} and sub_process_id = #{@sp2_2.id};
      
      select * from trackers where master_id = #{@master.id} and protocol_id = #{@p2.id};
    " 
    
    res = execute sql
    
    expect(res.count).to eq 1
    t = res.first
    
    expect(t['sub_process_id']).to eq @sp2_1.id.to_s # the original (but event date more recent) item should remain
        
    res = execute "select * from tracker_history where master_id = #{@master.id} and protocol_id = #{@p2.id};"
    
    expect(res.count).to eq(1), "Incorrect count #{res.count}. #{res.select  {|k| k.inspect} }\n#{sql}"
    t = res.first
    expect(t['sub_process_id']).to eq @sp2_1.id.to_s
  end
  
  it "updates the tracker item when the most recent tracker_history item is removed" do
    res = execute "
      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

      insert into trackers
      (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id) 
      values (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{DateTime.now -1.day}', now(), now(), #{@user_id});

      delete from tracker_history where 
      master_id = #{@master.id} and protocol_id = #{@p2.id} and sub_process_id = #{@sp2_1.id};
      
      select * from trackers where master_id = #{@master.id} and protocol_id = #{@p2.id};
    " 
    
    expect(res.count).to eq 1
    t = res.first
    
    expect(t['sub_process_id']).to eq @sp2_2.id.to_s # the original (but event date more recent) item should remain
        
    res = execute "select * from tracker_history where master_id = #{@master.id} and protocol_id = #{@p2.id};"
    
    expect(res.count).to eq 1
    t = res.first
    expect(t['sub_process_id']).to eq @sp2_2.id.to_s
    
    
  end
end
