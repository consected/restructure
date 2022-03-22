# frozen_string_literal: true

require 'rails_helper'
require 'benchmark'

RSpec.describe 'DynamicModelExtension::PlayerContactPhoneInfo', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include BulkMsg::AwsApiStubs

  # before :all do
  #   WebMock.disable_net_connect!(allow_localhost: true)
  #   # SetupHelper.get_webmock_responses
  # end

  before :example do
    create_admin

    apps = import_bulk_msg_app
    app = apps.first
    expect(app).to be_a Admin::AppType

    create_user nil, '', app_type: app
    create_master

    expect(@user.app_type_id).to eq app.id
    expect(@user.has_access_to?(:read, :general, :app_type)).to be_truthy

    @bulk_master = Master.find(-1)
    @bulk_master.current_user = @user

    # enable_user_app_access()
    # @user.app_type_id = app.first.id
    # @user.save!

    allow(User).to receive(:batch_user) { @user }
    @batch_user = User.use_batch_user(Settings.bulk_msg_app)

    setup_access :tracker
    let_user_create :trackers
    let_user_create :tracker_histories
    let_user_create :player_contacts
    let_user_create :dynamic_model__player_contact_phone_infos

    expect(@user.has_access_to?(:create, :table, :trackers)).to be_truthy
    expect(@user.has_access_to?(:create, :table, :player_contacts)).to be_truthy
    expect(@user.has_access_to?(:create, :table, :dynamic_model__player_contact_phone_infos)).to be_truthy

    ActiveRecord::Base.connection.execute <<~END_SQL
      delete from player_contact_phone_info_history;
      delete from player_contact_phone_infos;
    END_SQL

    create_master
    expect(@user.has_access_to?(:create, :table, :trackers)).to be_truthy
    @master.current_user = @user
    create_item(nil, @master) while PlayerContact.phone.where(rank: [5, 10]).count < 2

    expect(PlayerContact.phone.where(rank: [5, 10]).count).to be > 0
    expect(DynamicModel::PlayerContactPhoneInfo.count).to eq 0

    setup_stub(:pinpoint_validate)
    setup_stub(:sns_opt_out)
    setup_stub(:sns_opt_out_page2)
  end

  it 'lists player contact records that have not had phone number verified' do
    res = DynamicModel::PlayerContactPhoneInfo.incomplete_player_contacts limit: 50

    expect(res.count).to be > 0
    expect(res.first).to be_a PlayerContact
    expect(res.first.data).not_to be_blank
    expect(res.first.rec_type).to eq 'phone'
  end

  it 'validates player contact record phone numbers' do
    inc = DynamicModel::PlayerContactPhoneInfo.incomplete_player_contacts limit: 5
    expect(inc.count).to be > 0

    # Get the list of phone numbers from the incomplete list, so we can exclude them later
    datalist = inc.pluck(:data)

    # Now validate some contacts
    rescount = DynamicModel::PlayerContactPhoneInfo.validate_incomplete limit: 50, user: @batch_user

    expect(rescount).to be > 0

    # Check if the contacts have been validated
    newinc = DynamicModel::PlayerContactPhoneInfo.incomplete_player_contacts conditions: { data: datalist }
    expect(newinc.count).to eq 0
  end

  it 'pulls opt outs' do
    old_tracker = TrackerHistory.reorder('').last

    # Start by setting some player contact records to have known opt out numbers
    DynamicModel::PlayerContactPhoneInfo.validate_incomplete limit: 50, user: @batch_user
    pcpi_inst = DynamicModel::PlayerContactPhoneInfo.new
    list = pcpi_inst.list_sms_opt_outs.phone_numbers
    expect(list.length).to be >= 5
    i = 0

    DynamicModel::PlayerContactPhoneInfo.limit(5).each do |pcpi|
      pcpi.update!(current_user: @user, cleansed_phone_number_e164: list[i])
      pc = PlayerContact.find(pcpi.player_contact_id)
      pc.update!(current_user: @user, data: list[i].sub('+1', ''))
      i += 1
    end

    res = DynamicModel::PlayerContactPhoneInfo.update_opt_outs 1
    expect(res).to be > 0

    study = Classification::Protocol.active.where(name: 'Study').first

    tracker = TrackerHistory.where(protocol_id: study.id).reorder('').last

    expect(old_tracker.id).to be < tracker.id

    expect(tracker.protocol_name).to eq 'Study'
    expect(tracker.sub_process_name).to eq 'Opt Out'
    expect(tracker.protocol_event_name).to eq 'Text'
  end
end
