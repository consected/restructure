# frozen_string_literal: true

# Test the DynamicModelExtension::ZeusBulkMessageRecipient#set_response method.
#
# This spec demonstrates the scenario described in issue #1129:
# When a bulk message is scheduled to send in the future, the recipient
# update that records the send response is performed within a background
# job using the user that originally scheduled the message. If by that
# time the user has switched to a different app type (one that does not
# grant them edit access to the recipient table), the recipient update
# will fail in check_can_save with an FphsException.
#
# The fix temporarily switches the user's in-memory app_type to
# Settings.bulk_msg_app for the duration of the update, so the access
# checks pass when running under the background job.
require 'rails_helper'

RSpec.describe 'DynamicModelExtension::ZeusBulkMessageRecipient set_response', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport

  before :example do
    BulkMsgSupport.import_bulk_msg_app
    seed_database
    create_admin
    create_user

    # Ensure the user has access to the bulk message app (the app that
    # originally scheduled the bulk message)
    enable_user_app_access Settings.bulk_msg_app.name, @user

    # Set the user's current app_type to the bulk_msg_app and grant
    # create/update access to recipients in that app
    @user.app_type = Settings.bulk_msg_app
    @user.save!
    let_user_create :player_contacts, in_app_type: Settings.bulk_msg_app
    let_user_create :dynamic_model__zeus_bulk_message_recipients, in_app_type: Settings.bulk_msg_app
    let_user_create :dynamic_model__zeus_bulk_message_statuses, in_app_type: Settings.bulk_msg_app
    let_user_create :dynamic_model__zeus_bulk_messages, in_app_type: Settings.bulk_msg_app

    @bulk_master = Master.find(-1)
    @bulk_master.current_user = @user

    # Create a recipient as the user (acting in the bulk_msg_app)
    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(
      status: 'sent', name: 'test', channel: 'sms', message: 'message',
      send_date: DateTime.now, send_time: Time.now - 10.minutes
    )

    m = create_master
    pc = m.player_contacts.create(data: '(123)123-9999', rank: 10, rec_type: :phone)
    @recipient = @bulk_master.dynamic_model__zeus_bulk_message_recipients.create!(
      record_type: pc.resource_name.singularize, record_id: pc.id, data: pc.data,
      rank: pc.rank, response: nil, zeus_bulk_message_id: zbmsg.id
    )

    # Now simulate the user switching to a different app_type before the
    # background job runs. The other app type does not grant access to
    # the zeus_bulk_message_recipients table.
    @other_app_type = Admin::AppType.active.where.not(id: Settings.bulk_msg_app.id).first
    raise 'Need a second active app type to run this spec' unless @other_app_type

    enable_user_app_access @other_app_type.name, @user
    @user.app_type = @other_app_type
    @user.save!

    # Sanity check: the user does NOT have access to update the recipient
    # table in their current (non-bulk-msg) app type.
    expect(
      @user.has_access_to?(:edit, :table, 'dynamic_model__zeus_bulk_message_recipients')
    ).to be_falsey
  end

  it 'updates the recipient response when the user has switched away from the bulk message app type' do
    response_text = '[{"aws_sns_sms_message_id":"abc-123"}]'

    expect do
      @recipient.set_response @user, response_text
    end.not_to raise_error

    @recipient.reload
    expect(@recipient.response).to eq response_text
    expect(@user.app_type_id).to eq @other_app_type.id
  end

  it 'marks an existing message status as retrying and restores the user app type' do
    @user.app_type = Settings.bulk_msg_app
    status = @bulk_master.dynamic_model__zeus_bulk_message_statuses.create!(
      status: 'failure',
      current_user: @user,
      zeus_bulk_message_recipient_id: @recipient.id
    )
    @user.app_type = @other_app_type

    response_text = '[{"aws_sns_sms_message_id":"abc-456"}]'

    expect do
      @recipient.set_response @user, response_text
    end.not_to raise_error

    expect(status.reload.status).to eq 'retrying'
    expect(@user.app_type_id).to eq @other_app_type.id
  end
end
