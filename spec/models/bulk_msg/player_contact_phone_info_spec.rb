# frozen_string_literal: true

# Test the underlying SMS sending capability
# Actual notify functionality for any method of delivery is tested by SaveTriggers::NotifySpec
require 'rails_helper'

RSpec.describe 'DynamicModel::PlayerContactPhoneInfo', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include AwsApiStubs

  before :example do
    create_admin
    create_user
    import_bulk_msg_app

    # DynamicModel::PlayerContactPhoneInfo

    DynamicModel::PlayerContactPhoneInfo.definition.update_tracker_events
    @batch_user = User.batch_user
    @batch_user.update!(disabled: false, current_admin: @admin) if @batch_user.disabled?
    enable_user_app_access Settings.bulk_msg_app.name, @batch_user
    let_user_create :player_contacts, alt_user: @batch_user
    let_user_create :trackers, alt_user: @batch_user
    let_user_create :trackers, alt_user: @batch_user, in_app_type: Settings.bulk_msg_app
    let_user_create :dynamic_model__player_contact_phone_infos, alt_user: @batch_user
    let_user_create :dynamic_model__player_contact_phone_infos, alt_user: @batch_user, in_app_type: Settings.bulk_msg_app

    @bulk_master = Master.find(-1)
    @bulk_master.current_user = @user

    # @bms = DynamicModel::ZeusBulkMessageStatus.new
    let_user_create :player_contacts
    let_user_create :trackers, in_app_type: Settings.bulk_msg_app
    # let_user_create :dynamic_model__zeus_bulk_message_recipients
    # let_user_create :dynamic_model__zeus_bulk_message_statuses
    # let_user_create :dynamic_model__zeus_bulk_messages
    let_user_create :dynamic_model__player_contact_phone_infos
    let_user_create :dynamic_model__player_contact_phone_infos, in_app_type: Settings.bulk_msg_app

    # @bulk_master.dynamic_model__zeus_bulk_message_recipients.update_all(response: nil)

    @pcpi = DynamicModel::PlayerContactPhoneInfo.new

    setup_stub(:pinpoint_validate)
    setup_stub(:sns_opt_out)
    setup_stub(:sns_opt_out_page2)
  end

  def create_item_for_test(data = nil)
    m = create_master
    data ||= '(123)123-1230'
    pc = m.player_contacts.create(data: data, rank: 10, rec_type: :phone)

    user ||= pc.user
    master = pc.master
    master.current_user = user
    res = {}
    res[:player_contact_id] = pc.id
    res[:cleansed_phone_number_e164] = Formatter::Phone.format(data, format: :unformatted, default_country_code: 1)
    res[:cleansed_phone_number_national] = data
    let_user_create :dynamic_model__player_contact_phone_infos, alt_user: master.current_user
    let_user_create :trackers, alt_user: master.current_user

    master.dynamic_model__player_contact_phone_infos.create! res
  end

  it 'gets a list of SMS opt outs' do
    nt = nil
    max_iters = 2
    total_opt_outs = 0

    # Create a player contact info record for every opt out
    (0..max_iters).each do |_i|
      res = @pcpi.list_sms_opt_outs next_token: nt
      nt = res.next_token

      res.phone_numbers.each do |pn|
        create_item_for_test pn.gsub('+1', '')

        pcpi = DynamicModel::PlayerContactPhoneInfo.where(cleansed_phone_number_e164: pn).first
        expect(pcpi).not_to be nil

        total_opt_outs += 1
      end
      break unless nt
    end

    expect(total_opt_outs).to be > 0

    # Now run and update the records for real
    total_opt_outs = DynamicModel::PlayerContactPhoneInfo.update_opt_outs 1

    oo = DynamicModel::PlayerContactPhoneInfo.where('opted_out_at IS NOT NULL').count

    expect(oo).to be >= total_opt_outs
  end
end
