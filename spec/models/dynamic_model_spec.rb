require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Dynamic Model implementation', type: :model do

  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport


  before :all do
    create_admin
    create_user
    import_bulk_msg_app

    @bulk_master = Master.find(-1)
    @bulk_master.current_user = @user

    @bms = DynamicModel::ZeusBulkMessageStatus.new
    let_user_create :player_contacts
    let_user_create :dynamic_model__zeus_bulk_message_recipients
    let_user_create :dynamic_model__zeus_bulk_message_statuses
    let_user_create :dynamic_model__zeus_bulk_messages

    @bulk_master.dynamic_model__zeus_bulk_message_recipients.update_all(response: nil)

  end

  it "implements a dynamic model that can be disabled" do

    # Since recipients can be disabled, the class should provide a scope that allows just active recipients to be selected
    expect(DynamicModel::ZeusBulkMessageRecipient).to respond_to :active
  end

  it "implements a dynamic model that can store data" do
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
      restext = "[{\"aws_sns_sms_message_id\":\"#{rand(199999999999)}\"}]"

      recips << @bulk_master.dynamic_model__zeus_bulk_message_recipients.create!(record_id: pc.id, data: pc.data, rank: pc.rank, response: restext, zeus_bulk_message_id: zbmsg.id)
    end



  end

end
