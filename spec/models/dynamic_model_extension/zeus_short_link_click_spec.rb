# frozen_string_literal: true

require 'rails_helper'
require 'benchmark'

RSpec.describe 'DynamicModelExtension::ZeusShortLinkClick', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include AwsApiStubs

  before :example do
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_history

    import_bulk_msg_app

    @bulk_master = Master.find(-1)
    @bulk_master.current_user = @user

    let_user_create :player_contacts
    let_user_create :dynamic_model__zeus_bulk_message_recipients
    let_user_create :dynamic_model__zeus_bulk_message_statuses
    let_user_create :dynamic_model__zeus_short_links

    setup_stub(:s3_shortlink)
    setup_stub(:s3_head_shortlink)
    setup_stub(:s3_get_access_list)
    setup_stub(:s3_get_access_item)
  end

  it 'adds a short link record to a master record, ' do
    target_url = 'https://www.server.tld/join-us/'
    sl = DynamicModel::ZeusShortLink.new
    res = sl.create_link(target_url, master: @bulk_master)

    expect(res[:short_link_instance].shortcode).to eq res[:shortcode]
    expect(res[:link_domain]).to eq Settings::DefaultShortLinkS3Bucket

    b = sl.redirect_file_exists?(res[:shortcode])
    expect(b).to be true

    # Mock user to ensure we have a batch user
    allow(User).to receive(:batch_user) { User.active.first }

    # Pretend we have already retrieved older logs, to limit unnecessary S3 retrievals
    prefix_date = DateTime.now.iso8601.match(/\d+-\d+-\d+/)[0]

    c = DynamicModel::ZeusShortLinkClick.new
    logs = c.get_logs from_prefix_date: prefix_date
    expect(logs).to be_a Array
    expect(logs).to be_empty
  end
end
