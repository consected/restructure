require 'rails_helper'
require 'benchmark'

RSpec.describe "DynamicModel::ZeusShortLink", type: :model do

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

    let_user_create :player_contacts
    let_user_create :dynamic_model__zeus_bulk_message_recipients
    let_user_create :dynamic_model__zeus_bulk_message_statuses
    let_user_create :dynamic_model__zeus_short_links


  end


  it "generates an HTML document for redirection" do
    target_url = 'https://google.com?something#aT_Here"is good'
    res = DynamicModel::ZeusShortLink.generate_html target_url
    expect(res).to include '<script>window.location.href="https://google.com?something#aT_Here\\"is good";</script>'
  end

  it "generates a shortcode" do
    res = DynamicModel::ZeusShortLink.generate_shortcode
    expect(Base64.urlsafe_decode64(res).length).to eq 6
  end

  it "adds a short link record to a master record, generating shortcode and html, and pushing the file to S3" do
    target_url = 'https://footballplayershealth.harvard.edu/join-us/'
    sl = DynamicModel::ZeusShortLink.new
    res = sl.create_link(target_url, master: @bulk_master)

    expect(res[:shortcode].length).to be > 6
    expect(res[:short_link_instance]).to be_persisted
    expect(res[:short_link_instance]).to be_a DynamicModel::ZeusShortLink
    expect(res[:short_link_instance].shortcode).to eq res[:shortcode]
    expect(res[:html]).to include '<script>window.location.href="'+target_url+'";</script>'
    expect(res[:link_domain]).to eq Settings::DefaultShortLinkS3Bucket

    b = sl.redirect_file_exists?(res[:shortcode])

    expect(b).to be true

  end

  it "generates a short URL in a message" do
    txt = "A short message with a generated URL [[shortlink https://footballplayershealth.harvard.edu/join-us/?test_id={{ids.msid}}]]\nThanks!"
    last_msid = (Master.order(msid: :desc).first.msid || 123) + 1
    @master = Master.create! current_user: @user, msid: last_msid
    @player_contact = @master.player_contacts.create! data: '(123)123-1234', rec_type: :phone, rank: 10

    alt = @master.player_contacts.create! data: '(123)123-1234 alt', rec_type: :phone, rank: 5

    data = Admin::MessageTemplate.setup_data(@player_contact, alt)
    res = Admin::MessageTemplate.substitute txt, data: data, tag_subs: nil

    sl = DynamicModel::ZeusShortLink.last
    expect(sl).to be_a DynamicModel::ZeusShortLink
    expect(sl.url).to eq "https://footballplayershealth.harvard.edu/join-us/?test_id=#{last_msid}"
    expect(sl.master_id).to eq @master.id
    expect(res).to eq txt = "A short message with a generated URL #{sl.short_url}\nThanks!"

    expect(sl.for_item_type).not_to be nil
    expect(sl.for_item_id).not_to be nil

    c = sl.for_item_type.ns_camelize.constantize
    expect(c).to eq PlayerContact

    o = c.find(sl.for_item_id)
    expect(o.data).to eq '(123)123-1234 alt'

  end

  it "stress tests creating many" do

    test_times = 10

    txt = "A short message with a generated URL [[shortlink https://footballplayershealth.harvard.edu/join-us/?test_id={{ids.msid}}]]\nThanks!"
    last_msid = (Master.order(msid: :desc).first.msid || 123) + 1

    masters = []

    test_times.times do
      master = Master.create! current_user: @user, msid: last_msid
      masters << master
      master.player_contacts.create! data: '(123)123-1234', rec_type: :phone, rank: 10
      master.player_contacts.create! data: '(123)123-1234 alt', rec_type: :phone, rank: 5
      last_msid += 1
    end

    expect(masters.length).to eq test_times

    t = Benchmark.realtime do
      masters.each do |master|
        data = Admin::MessageTemplate.setup_data(master.player_contacts[0], master.player_contacts[1])
        res = Admin::MessageTemplate.substitute txt.dup, data: data, tag_subs: nil

        sl = DynamicModel::ZeusShortLink.last
        expect(sl).to be_a DynamicModel::ZeusShortLink
        expect(sl.url).to eq "https://footballplayershealth.harvard.edu/join-us/?test_id=#{master.msid}"
      end
    end

    puts "It took #{t} seconds to create #{test_times} shortlinks"

    expect(t).to be < 5


  end

  it "gets logs from s3" do

  end

end
