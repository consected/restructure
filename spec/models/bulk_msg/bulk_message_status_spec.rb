# frozen_string_literal: true

# Test the underlying SMS sending capability
# Actual notify functionality for any method of delivery is tested by SaveTriggers::NotifySpec
require 'rails_helper'

RSpec.describe 'DynamicModel::ZeusBulkMessageStatus', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include AwsApiStubs

  before :all do
    WebMock.disable_net_connect!(allow_localhost: true)
    # SetupHelper.get_webmock_responses
  end

  # after :all do
  #   WebMock.allow_net_connect!
  # end

  before :example do
    BulkMsgSupport.import_bulk_msg_app
    seed_database
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_history

    @bulk_master = Master.find(-1)
    @bulk_master.current_user = @user

    @bms = DynamicModel::ZeusBulkMessageStatus.new
    let_user_create :player_contacts
    let_user_create :dynamic_model__zeus_bulk_message_recipients
    let_user_create :dynamic_model__zeus_bulk_message_statuses
    let_user_create :dynamic_model__zeus_bulk_messages

    has_ranks = Classification::GeneralSelection.active.pluck(:item_type).select { |a| a == 'dynamic_model__zeus_bulk_message_recipients_rank' }
    expect(has_ranks.length).to be > 0

    @bulk_master.dynamic_model__zeus_bulk_message_recipients.update_all(response: nil)

    setup_stub(:sns_log)
    setup_stub(:sns_direct_publish)
    setup_stub(:sns_direct_publish_page2)
    setup_stub(:sns_direct_publish_10)
    setup_stub(:sns_direct_publish_10_page2)
    setup_stub(:sns_direct_publish_failure)
    setup_stub(:sns_direct_publish_failure_page2)
    setup_stub(:sns_direct_publish_no_limit)
    setup_stub(:sns_direct_publish_10_start_empty)
    setup_stub(:sns_direct_publish_10_failed_empty)
    # setup_stub(:sns_direct_publish_11_empty)
  end

  it 'associates with the recipient list' do
    pcs = []
    max_num = 3
    recips = []

    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(status: 'sent', name: 'test', channel: 'sms', message: 'message', send_date: DateTime.now, send_time: Time.now - 10.minutes)
    9.times do |n|
      m = create_master
      # We need a range of timestamps
      sleep 1.2 if n == max_num - 1 || n == max_num
      pcs << m.player_contacts.create(data: "(123)123-123#{n}", rank: 10, rec_type: :phone)
      pc = pcs[n]
      restext = "[{\"aws_sns_sms_message_id\":\"#{rand(199_999_999_999)}\"}]"

      recips << @bulk_master.dynamic_model__zeus_bulk_message_recipients.create!(record_id: pc.id, data: pc.data, rank: pc.rank, response: restext, zeus_bulk_message_id: zbmsg.id)
    end

    num = 0
    statuses = []

    # Ensure status dates are later than recipient dates
    sleep 2
    # Skip the first one
    pcs.each do |_pc|
      num += 1
      statuses << @bulk_master.dynamic_model__zeus_bulk_message_statuses.create!(status: 'success', zeus_bulk_message_recipient_id: recips[num].id)
      break if num == max_num
    end

    # Ensure the date comes from the database, not the Rails time, since they can be slightly different
    r0 = recips[0].reload
    not_done = DynamicModel::ZeusBulkMessageStatus.earliest_incomplete_timestamp
    expect(r0.created_at).to eq not_done

    # Now fill the first one
    statuses << @bulk_master.dynamic_model__zeus_bulk_message_statuses.create!(status: 'success', zeus_bulk_message_recipient_id: recips[0].id)

    not_done = DynamicModel::ZeusBulkMessageStatus.earliest_incomplete_timestamp
    not_done_id = DynamicModel::ZeusBulkMessageStatus.incomplete_recipients.first.id

    # No results will return if there is no associated zeus_bulk_message record, or its status isn't sent
    # We shouldn't be checking for results from items that haven't been sent or are only scheduled, since that is a waste
    # Generate a zeus_bulk_message and associate it with the recipients so the checks can progress
    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(status: 'draft', name: 'test', channel: 'sms', message: 'message', send_date: DateTime.now, send_time: Time.now - 10.minutes)
    recips.each do |r|
      r.update!(zeus_bulk_message_id: zbmsg.id, current_user: @user)
    end
    expect(DynamicModel::ZeusBulkMessageStatus.earliest_incomplete_timestamp).to be nil

    # Any message sent more than 5 days ago also shouldn't be checked
    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(status: 'sent', name: 'test', channel: 'sms', message: 'message', send_date: DateTime.now - 11.days, send_time: Time.now - 10.minutes, updated_at: DateTime.now - 11.days)
    recips.each do |r|
      r.update!(zeus_bulk_message_id: zbmsg.id, current_user: @user)
    end
    expect(DynamicModel::ZeusBulkMessageStatus.earliest_incomplete_timestamp).to be nil

    # Sent status of message to sent, like in real life, allowing incomplete results to be returned
    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(status: 'sent', name: 'test', channel: 'sms', message: 'message', send_date: DateTime.now, send_time: Time.now - 10.minutes)
    recips.each do |r|
      r.update!(zeus_bulk_message_id: zbmsg.id, current_user: @user)
    end
    expect(DynamicModel::ZeusBulkMessageStatus.earliest_incomplete_timestamp).not_to be nil

    # Ensure the date comes from the database, not the Rails time
    r0 = recips[num + 1].reload
    expect(r0.id).to eq not_done_id
    expect(r0.created_at).to eq not_done

    # Fill the remaining items

    (9 - max_num - 1).times do |n|
      statuses << @bulk_master.dynamic_model__zeus_bulk_message_statuses.create!(status: 'success', zeus_bulk_message_recipient_id: recips[n + max_num + 1].id)
    end

    not_done = DynamicModel::ZeusBulkMessageStatus.earliest_incomplete_timestamp

    expect(not_done).to be nil
  end

  it 'can access log groups' do
    lg = @bms.aws_log_groups
    expect(lg.length).to be > 0

    expect(lg[:failure]).not_to be nil
    expect(lg[:success]).not_to be nil

    # puts lg
  end

  # NOTE: this test may fail if we have not sent a sufficient
  # number of test messages recently
  it 'can pull logs' do
    # Limit 1 to test paging

    res = @bms.delivery_responses :success, limit: 10
    expect(res[:raw_events].length).to be == 10
    expect(res[:events].length).to be == 10
    expect(res[:more_results]).to be true

    first_ts = res[:raw_events].first.timestamp
    expect(first_ts).not_to be nil
    last_ts = res[:raw_events].last.timestamp
    expect(last_ts).to eq res[:max_timestamp]

    e1 = res[:events].first
    expect(e1[:status]).to eq :success
    mids = res[:events].map { |r| r[:message_id] }

    # Pull a second page
    res = @bms.delivery_responses :success, limit: 10
    expect(res[:raw_events].length).to be > 0

    # if res[:raw_events].length < 10
    #   expect(res[:more_results]).to be false
    # else
    #   expect(res[:more_results]).to be true
    # end

    new_mids = res[:events].map { |r| r[:message_id] }
    expect(mids).not_to eq new_mids

    ev = res[:events].first
    expect(ev[:message_id]).to match(/[a-z0-9]+-[a-z0-9]+-[a-z0-9]+-[a-z0-9]+/)
    expect(ev[:timestamp]).to be_a Integer

    # Ensure nothing is returned
    res = @bms.delivery_responses :success, limit: 10, start_timestamp: (DateTime.now + 1000.seconds)
    expect(res[:events].length).to be == 0
    expect(res[:more_results]).to be false

    # Erroneously attempt to pull another next page
    res = @bms.delivery_responses :success, limit: 11
    expect(res).to be nil
  end

  it 'matches a delivery log to a recipient message id' do
    res = @bms.delivery_responses :success, limit: 9, next_page: false

    mids = res[:events].map { |r| r[:message_id] }
    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(status: 'sent', name: 'test', channel: 'sms', message: 'message', send_date: DateTime.now, send_time: Time.now - 10.minutes)

    pcs = []
    recips = []
    9.times do |n|
      m = create_master
      pcs << m.player_contacts.create(data: "(123)123-123#{n}", rank: 10, rec_type: :phone)
      pc = pcs[n]
      expect(mids[n]).not_to be nil
      restext = "[{\"aws_sns_sms_message_id\":\"#{mids[n]}\"}]"
      recips << @bulk_master.dynamic_model__zeus_bulk_message_recipients.create!(record_id: pc.id, data: pc.data, rank: pc.rank, response: restext, zeus_bulk_message_id: zbmsg.id)
    end

    r = DynamicModel::ZeusBulkMessageStatus.find_matching_recipient_by_message_id('junk')
    expect(r).to be nil

    n = 0
    res[:events].each do |ev|
      r = DynamicModel::ZeusBulkMessageStatus.find_matching_recipient_by_message_id(ev[:message_id])
      expect(r.id).to eq recips[n].id
      n += 1
    end
  end

  it 'add status records from logged delivery events' do
    res = @bms.delivery_responses :success, limit: 9, next_page: false
    mids = res[:events].map { |r| r[:message_id] }

    res = @bms.delivery_responses :failure, limit: 9, next_page: false
    mids += res[:events].map { |r| r[:message_id] }

    pcs = []
    recips = []

    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(status: 'sent', name: 'test', channel: 'sms', message: 'message', send_date: DateTime.now, send_time: Time.now - 10.minutes)

    mids.length.times do |n|
      m = create_master
      pcs << m.player_contacts.create(data: "(123)123-1234 ext #{n}", rank: 10, rec_type: :phone)
      pc = pcs[n]
      expect(mids[n]).not_to be nil
      restext = "[{\"aws_sns_sms_message_id\":\"#{mids[n]}\"}]"
      recips << @bulk_master.dynamic_model__zeus_bulk_message_recipients.create!(record_id: pc.id, data: pc.data, rank: pc.rank, response: restext, zeus_bulk_message_id: zbmsg.id)
    end

    DynamicModel::ZeusBulkMessageRecipient.update_all(created_at: DateTime.now - 10.years)

    res = DynamicModel::ZeusBulkMessageStatus.add_status_from_log limit: 9

    expect(res.length).to be > 0
  end
end
