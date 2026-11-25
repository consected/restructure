# frozen_string_literal: true

# System regression spec for the master address `data-address-is-us` block attribute (issue #1594).
# The custom_block_attrs partial previously evaluated the attribute template against the attribute
# string instead of the address record, so every address rendered as US. This verifies the attribute
# reflects each record's country, so the US / non-US address fields display correctly.

require 'rails_helper'

describe 'address data-address-is-us block attribute', js: true, driver: $browser_driver do # rubocop:disable Style/GlobalVars
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup
    @admin, = create_admin
    create_data_set_outside_tx
    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email
    setup_access :addresses
    setup_access :addresses, user: @user
    @master.current_user = @user
    @non_us_address = @master.addresses.create!(country: 'ca', street: '1 maple st', region: 'alberta', rank: 10)
    @us_address = @master.addresses.create!(country: 'us', street: '2 main st', state: 'ma', zip: '02115', rank: 5)
  end

  before(:each) do
    validate_setup
    login
  end

  it 'sets data-address-is-us from each address record country' do
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    dismiss_modal
    expect(page).to have_css("#master-#{@master.id}")
    expand_master_record(master_id: @master.id)

    addresses_list = "[data-sub-list='addresses']"
    expect(page).to have_css("#{addresses_list} ul[data-item-id='#{@non_us_address.id}'][data-address-is-us='false']",
                             visible: :all, wait: 20)
    expect(page).to have_css("#{addresses_list} ul[data-item-id='#{@us_address.id}'][data-address-is-us='true']",
                             visible: :all, wait: 20)
  end
end
