# frozen_string_literal: true

require 'rails_helper'

describe 'tracker record update', js: true, driver: :app_firefox_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup

    create_admin

    # sp = Classification::SubProcess.first

    Classification::ProtocolEvent.enabled.each do |d|
      d.update! disabled: true, current_admin: @admin # , sub_process: sp
    end

    seed_database
    create_data_set_outside_tx no_trackers: true

    @user, @good_password = create_user
    @good_email = @user.email
  end

  before :each do
    validate_setup

    login
  end

  def expect_tracker_date_to_be_today
    sleep 0.01
    f = find('#tracker_event_date')
    d = DateTime.now
    expect(f.value).to match(%r{0?#{d.month}/0?#{d.day}/#{d.year}})
  end

  it 'should create a new tracker item when a player record is added or updated' do
    visit '/masters/search'

    # Switch to advanced search form
    within '#simple_search_master' do
      find('#master_general_infos_attributes_0_first_name').click
    end
    within '.advanced-form-selections' do
      click_button 'Advanced Search'
    end

    # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced-form.in'

    # Search for the player
    within '#advanced_search_master' do
      click_link 'clear fields'
      fill_in 'master_player_infos_attributes_0_first_name', with: @full_player_info.first_name
      fill_in 'master_player_infos_attributes_0_last_name', with: @full_player_info.last_name.to_s
      sleep 1
      find("\#master_player_infos_attributes_0_last_name").send_keys :tab
    end

    have_css '#advanced_search_master.ajax-running'
    sleep 1
    expect(page).to have_css '#master_results_block', text: ''
    has_css? '#search_count .search_count'
    sleep 2
    v = find('#search_count').text
    unless v&.match(/[0-9]+/)
      puts 'About to fail'
      puts @full_player_info.inspect
      sleep 10
    end

    expect(page).to have_css '#search_count .search_count', text: /[0-9]+/
    expect(page).not_to have_css '#advanced_search_master.ajax-running'

    # Check we got some results
    items = page.all(:css, '.master-expander')
    expect(items.length).to be > 0

    # Ensure all the results match what we searched for
    page.all(:css, '.master-expander .player-info-header .player-names').each do |el|
      expect(el.text).to match(/#{@full_player_info.first_name.capitalize}.*/)
    end

    @master_id = all('.master-result .master_id').first.text
    expect(@master_id).not_to be nil
    @master = Master.find(@master_id)

    # Now jump into the record result
    open_player_element items.first, items

    # add a player contact phone record

    click_link 'Contact record'

    phone = '(615)876-6815'
    within 'form#new_player_contact' do
      select 'Phone', from: 'Record type'
      fill_in 'Phone', with: phone
      click_button 'Save'
    end
    sleep 1
    have_css '.tracker-block.collapse.in'

    pc_rec = @master.player_contacts.where(data: phone).first

    protocol = Classification::Protocol.active.where(name: 'Updates').first

    paperclip = nil

    # After a moment the tracker will show the newly created item
    expect(page).to have_css 'tbody[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"]'
    within 'tbody[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"]' do |_t|
      have_css('span.record-meta', text: "by #{@user.email}")
      paperclip = all("a.tracker-link-to-item[href='#player-contact-#{@master_id}-#{pc_rec.id}']").first
      expect(paperclip).not_to be nil
    end

    paperclip.click

    expect(page).to have_css("#player-contact-#{@master_id}-#{pc_rec.id}.item-highlight")
  end

  after(:all) do
  end
end
