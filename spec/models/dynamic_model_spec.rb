# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Dynamic model implementation description using both imported apps and direct configurations
RSpec.describe 'Dynamic Model implementation', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include DynamicModelSupport

  before :all do
    expect(Admin::MigrationGenerator.view_definition('dynamic_test', 'test_views')).to be nil
    generate_test_dynamic_view
  rescue StandardError => e
    puts e
  end

  before :example do
    # Seeds.setup

    @user0, = create_user
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_history

    import_bulk_msg_app
    dm = DynamicModel::ZeusBulkMessage.definition
    dm.current_admin = @admin
    dm.update_tracker_events

    @bulk_master = Master.find(-1)
    @bulk_master.current_user = @user

    @bms = DynamicModel::ZeusBulkMessageStatus.new
    let_user_create :player_contacts
    let_user_create :dynamic_model__zeus_bulk_message_recipients
    let_user_create :dynamic_model__zeus_bulk_message_statuses
    let_user_create :dynamic_model__zeus_bulk_messages

    @bulk_master.dynamic_model__zeus_bulk_message_recipients.update_all(response: nil)
  end

  it 'implements a dynamic model that can be disabled' do
    # Since recipients can be disabled, the class should provide a scope that allows just active recipients to be selected
    expect(DynamicModel::ZeusBulkMessageRecipient).to respond_to :active
  end

  it 'implements a dynamic model that can store data' do
    pcs = []
    max_num = 3

    recips = []

    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(status: 'sent', name: 'test', channel: 'sms', message: 'message', send_date: DateTime.now, send_time: Time.now - 10.minutes)
    2.times do |n|
      m = create_master
      # We need a range of timestamps
      sleep 1.2 if n == max_num - 1 || n == max_num
      pcs << m.player_contacts.create(data: "(123)123-123#{n}", rank: 10, rec_type: :phone)
      pc = pcs[n]
      restext = "[{\"aws_sns_sms_message_id\":\"#{rand(199_999_999_999)}\"}]"

      recips << @bulk_master.dynamic_model__zeus_bulk_message_recipients.create!(record_id: pc.id, data: pc.data, rank: pc.rank, response: restext, zeus_bulk_message_id: zbmsg.id)
    end
  end

  it "saves the current user's user_id if the created_by_user_id field is present" do
    generate_test_dynamic_model

    rec = @master.dynamic_model__test_created_by_recs.create! test1: 'abc'
    expect(rec).to be_a DynamicModel::TestCreatedByRec

    rec = DynamicModel::TestCreatedByRec.find rec.id
    expect(rec).to be_persisted
    expect(rec.user_id).to eq @user.id
    # Expect the created_by_user_id field value to match the current user
    expect(rec.created_by_user_id).to eq @user.id

    rec.update!(current_user: @user0, test2: 'def')
    rec = DynamicModel::TestCreatedByRec.find rec.id

    expect(rec.user_id).to eq @user0.id
    # Expect the created_by_user_id field value to be unchanged
    expect(rec.created_by_user_id).to eq @user.id

    expect(rec).to respond_to :created_by_user_name
    expect(rec.created_by_user_name).to eq @user.email
  end

  it 'creates a view using supplied SQL' do
    Admin::MigrationGenerator.view_definition 'dynamic_test', 'test_views'
  end

  it 'sets an initial config if the table already exists' do
    unless Admin::MigrationGenerator.table_exists? 'test_created_by_recs'
      TableGenerators.dynamic_models_table('test_created_by_recs', :create_do, 'test1', 'test2', 'created_by_user_id')
    end

    table_comment = 'a test table'
    test2_comment = 'test2 column comment'

    Admin::MigrationGenerator.connection.execute <<~END_SQL
      comment on table test_created_by_recs is '#{table_comment}';
      comment on column test_created_by_recs.test2 is '#{test2_comment}';
    END_SQL

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test created by',
                              table_name: 'test_created_by_recs',
                              schema_name: 'ml_app',
                              category: :test

    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a ::DynamicModel
    # The field list has been set up
    expect(dm.field_list).to eq 'test1 test2 created_by_user_id'
    # The keys have been set up automatically
    expect(dm.foreign_key_name).to eq 'master_id'
    expect(dm.primary_key_name).to eq 'id'
    # A baseline set of comments have been set up
    tcs = dm.table_comments
    # The default comment 'Dynamicmodel: Test Created By' should not be used
    expect(tcs[:table]).to eq table_comment
    expect(tcs[:fields][:test2]).to eq test2_comment
  end
end
