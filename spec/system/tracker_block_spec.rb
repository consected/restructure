# frozen_string_literal: true

require 'rails_helper'

describe 'tracker block', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:each) do
    SetupHelper.feature_setup

    create_admin

    Classification::ProtocolEvent.enabled.each do |d|
      d.update! disabled: true, current_admin: @admin # , sub_process: sp
    end

    seed_database
    create_data_set_outside_tx no_trackers: true, no_seed: true

    # Clean any stale tracker records from previous test runs on the reference master,
    # since the data set was created with no_trackers: true
    if @master
      TrackerHistory.where(master_id: @master.id).delete_all
      Tracker.where(master_id: @master.id).delete_all
    end

    # a blank master to test for empty tracker record sets
    # we have to force a new thread and connection to make this a transaction outside of the normal flow,
    # otherwise the Selenium session may not see it

    @user, @good_password = create_user nil, '', create_master: true
    @good_email = @user.email

    setup_access :player_contacts
    setup_access :player_infos
    setup_access :trackers
    setup_access :tracker_histories
    setup_access :create_master, resource_type: :general, access: :read, user: @user

    # end

    # before :each do
    validate_setup

    setup_access :player_contacts, user: @user
    setup_access :player_infos, user: @user
    setup_access :trackers, user: @user
    setup_access :tracker_histories, user: @user
    setup_access :create_master, resource_type: :general, access: :read, user: @user

    login
  end

  # The browser's local "today" (the value the date field defaults to), which may differ from the Ruby server's date
  def browser_local_today
    Date.parse(page.evaluate_script('(new Date()).asYMD()'))
  end

  def tracker_date_matches?(dd, d)
    if dd[:type] == 'date'
      dd.value.match?(/#{d.year}-0?#{d.month}-0?#{d.day}/)
    else
      dd.value.match?(%r{0?#{d.month}/0?#{d.day}/#{d.year}})
    end
  end

  # Non-waiting probe: true if the tracker event date field holds the given date (default: browser today)
  def tracker_field_event_date(match_date = nil)
    tracker_date_matches?(find('.tracker-event_date input'), match_date || browser_local_today)
  end

  # Retries until the event date field shows today's date in the browser's local time zone
  def expect_tracker_date_to_be_today
    today = browser_local_today
    page.document.synchronize(10) do
      raise Capybara::ExpectationNotMet, "tracker event date is not #{today}" unless tracker_field_event_date(today)
    end
  end

  it 'should create a new tracker item in an empty list' do
    ac = @user.can? :create_master
    expect(ac).to be_truthy
    # Be sure that the page is showing the menu correctly

    click_link 'Create Master'
    dismiss_modal

    # click a test only hidden button to generate a completely empty master record
    # Without this, the player info record that is normally created doesn't provide a completely empty set of tracker records
    # We must test this edge case, since it has broken the UI in development

    expect(page).to have_css('form#new_master', wait: 10)
    within 'form#new_master' do
      all('input[type="submit"]').first.click
    end

    dismiss_modal
    expand_tracker_panel

    expect(page).to have_css('.tracker-tree-results a.add-tracker-record', wait: 10)

    within '.tracker-tree-results' do
      find('a.add-tracker-record').click
    end

    # Wait for the new tracker form to show
    expect(page).to have_css('#new_tracker')
  end

  it 'should create a new tracker item' do
    visit '/masters/search'
    dismiss_modal

    # Switch to advanced search form
    within '#simple_search_master' do
      find('#master_general_infos_attributes_0_first_name').click
    end
    within '.advanced-form-selections' do
      click_button 'Advanced Search'
    end

    # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced-form.in'
    expect(page).to have_no_css '#master-search-advanced-form.in.collapsing'

    # Search for the player
    within '#advanced_search_master' do
      click_link 'clear fields'
      fill_in 'master_player_infos_attributes_0_first_name', with: @full_player_info.first_name
      fill_in 'master_player_infos_attributes_0_last_name', with: @full_player_info.last_name.to_s
      find('#master_player_infos_attributes_0_last_name').send_keys :tab
    end

    # The search runs via AJAX; the running state may be brief, so wait for the settled results instead
    dismiss_modal
    expect(page).to have_css '#master_results_block', wait: 10
    expect(page).not_to have_css '#advanced_search_master.ajax-running'

    dismiss_modal
    expect(page).to have_css '#search_count .search_count', wait: 10
    expect(page).to have_css '#search_count', text: /[0-9]+/, wait: 15

    # Check we got some results
    items = page.all(:css, '.master-expander')
    expect(items.length).to be > 0

    # Ensure all the results match what we searched for
    page.all(:css, '.master-expander .player-info-header .player-names').each do |el|
      expect(el.text).to match(/#{@full_player_info.first_name.capitalize}.*/)
    end

    # Now jump into the record result
    h = open_player_element items.first, items

    # Open the tracker panel if there are no items in it and it is collapsed
    #    t = all('[data-template="tracker-badge-template"]')
    #    if t.first.text == '0'
    #      t.click
    #    end

    # Validate that we don't already have a protocol / sub process tracked for this player
    protocol = Classification::Protocol.active.selectable.find_by(name: 'Q1')
    sps = protocol.sub_processes.enabled.where.not(name: 'Alerts')

    spslen = sps.length
    expect(spslen).to be_positive

    sp = nil
    pe = nil
    pe_orig = nil
    pes = nil
    sp_orig = nil
    i = 0
    while pe.nil?
      sp = pick_one_from sps
      sp_orig = sp
      pes = sp.protocol_events.enabled.reload
      pe = pes[i]
      pe_orig = pe
      i += 1
      expect(i).to be <= spslen
    end

    expand_tracker_panel
    expect(page).not_to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-protocol_name", text: protocol.name
    expect(page).not_to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-sub_process_name", text: sp.name.captionize

    # Now add a new tracker item
    within '.tracker-tree-results' do
      find('a.add-tracker-record').click
    end

    # Wait for the new tracker form to show
    expect(page).to have_css '.tracker-tree-results #new_tracker'

    # Enter new tracker details
    within '.tracker-tree-results #new_tracker' do
      select protocol.name, from: 'tracker_protocol_id'
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp.id}']").select_option
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp.id}'] option[value='#{pe.id}']").select_option
      expect_tracker_date_to_be_today
      click_button 'Create Tracker'
    end
    dismiss_modal
    # After a moment the tracker will show the newly created item
    expect(page).to have_css 'tbody[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase.underscore + '"] span.record-meta', text: @user.email.to_s

    expect(page).to have_css '.tracker-tree-results tbody.new-block', wait: 10
    dismiss_modal
    dismiss_modal
    # Now add a new item to be merged within the current protocol
    pe = pes[1]
    within '.tracker-tree-results' do
      find('a.add-tracker-record').click
    end

    expect(page).to have_css '.tracker-tree-results #new_tracker', wait: 10

    within '.tracker-tree-results #new_tracker' do
      select protocol.name, from: 'tracker_protocol_id'
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp.id}']").select_option

      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp.id}'] option[value='#{pe.id}']").select_option
      # We have to set this explicitly rather than use fill_in, since the shim for date fields in Firefox creates a separate input

      dd = find('.tracker-event_date input')
      if dd[:type] == 'date'
        dd.send_keys '2030-02-02'
      else
        dd.set ''
        dd.set '02/02/2030'
      end
      click_button 'Create Tracker'
    end

    # Validate the new item was created as the current record of the same protocol
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"] span.record-meta', text: @user.email.to_s
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"] .tracker-event_date', text: %r{0?2/0?2/2030}
    # Now try an earlier item
    within '.tracker-tree-results' do
      find('a.add-tracker-record').click
    end

    expect(page).to have_css '.tracker-tree-results #new_tracker', wait: 10

    within '.tracker-tree-results #new_tracker' do
      select protocol.name, from: 'tracker_protocol_id'
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp.id}']").select_option
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp.id}'] option[value='#{pe.id}']").select_option
      # We have to set this explicitly rather than use fill_in, since the shim for date fields in Firefox creates a separate input
      dd = find('.tracker-event_date input')
      if dd[:type] == 'date'
        dd.send_keys '2010-01-02'
      else
        dd.set ''
        dd.set '01/02/2010'
      end
      click_button 'Create Tracker'
    end

    # Validate the new item was NOT created as the current record of the same protocol
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"] span.record-meta', text: @user.email.to_s
    expect(page).not_to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"] .tracker-event_date', text: '1/2/2010'

    # Click into the history to check the previous record is now visible there
    within 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"]' do
      click_link 'show history'
    end

    expect(page).to have_css 'tbody.tracker-history .tracker-history-event_name', text: pe_orig.name.captionize
    expect(page).to have_css 'tbody.tracker-history .tracker-history span.record-meta', text: @user.email.to_s

    # Search for the player by current Classification::Protocol, subprocess and event
    dismiss_modal
    click_link 'clear fields'
    within '#advanced_search_master' do
      fill_in 'master_player_infos_attributes_0_first_name', with: @full_player_info.first_name
      fill_in 'master_player_infos_attributes_0_last_name', with: @full_player_info.last_name.to_s
      find('#master_player_infos_attributes_0_last_name').send_keys :tab
      select protocol.name, from: 'master_trackers_attributes_0_protocol_id'
      find("#master_trackers_attributes_0_sub_process_id option[value='#{sp.id}']").select_option
      find("#master_trackers_attributes_0_protocol_event_id option[value='#{pe.id}']").select_option
    end

    dismiss_modal
    # Results load via AJAX; wait for them rather than retrying the search with a fixed pause
    expect(page).to have_css '.master-expander', wait: 15
    items = page.all(:css, '.master-expander')
    expect(items.length).to be > 0

    # Open the first person
    h = open_player_element items.first, items

    # We know the tracker has records, so open the tracker panel
    expand_tracker_panel

    # Validate the current protocol item appears as expected
    expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-protocol_name", text: protocol.name
    expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-sub_process_name", text: sp.name.capitalize
    expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-event_name", text: /#{pe.name}/i

    # Show the history
    within 'tbody[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"]' do
      click_link 'show history'
    end

    expect(page).to have_css 'tbody.tracker-history .tracker-history-event_name'

    # The previous item is there still
    expect(page).to have_css('tbody.tracker-history .tracker-history-event_name', text: /#{pe_orig.name}/i), "Tracker history event name not found '#{pe_orig.name}'. #{page.all("##{h}.tracker-history").first&.text}"
    expect(page).to have_css 'tbody.tracker-history .tracker-history span.record-meta', text: @user.email.to_s

    # Search for the player by current Classification::Protocol, subprocess and event, but not the historical event
    within '#advanced_search_master' do
      find("#master_not_tracker_histories_attributes_0_sub_process_id option[value='#{sp.id}']").select_option
      find("#master_not_tracker_histories_attributes_0_protocol_event_id option[value='#{pe_orig.id}']").select_option
    end

    # We expect no results, as we know this player has that historical record
    expect(page).to have_css '.search_count', text: '0'

    # Now remove the Not condition, and instead require the historical item
    within '#advanced_search_master' do
      find("#master_not_tracker_histories_attributes_0_sub_process_id option[value='']").select_option
      find("#master_not_tracker_histories_attributes_0_protocol_event_id option[value='']").select_option
      find("#master_tracker_histories_attributes_0_sub_process_id option[value='#{sp.id}']").select_option
      find("#master_tracker_histories_attributes_0_protocol_event_id option[value='#{pe_orig.id}']").select_option
    end

    dismiss_modal
    # The results should show at least this one player
    expect(page).to have_css '.master-expander', wait: 15
    items = page.all(:css, '.master-expander')

    expect(items.length).to be > 0

    h = open_player_element items.first, items
    within "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}']" do
      edit_link = find('a.edit-tracker', visible: :all, wait: 10)
      # Scroll into view and click using JavaScript since element exists but may not be interactable
      page.execute_script('arguments[0].scrollIntoView(true);', edit_link)
      click_link 'edit tracker record'
    end

    pe_new = nil
    sp_new = nil

    while pe_new.nil? || sp_new.nil?
      sp_new = pick_one_from sps
      pes_new = sp_new.protocol_events.enabled.reload

      pe_new = pick_one_from pes_new
    end

    dismiss_modal

    within "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] form" do
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp_new.id}']").select_option
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp_new.id}'] option[value='#{pe_new.id}']").select_option

      # Avoid a failure when we don't need to
      expect_tracker_date_to_be_today unless tracker_field_event_date(Date.parse('2030-02-02'))

      # We have to set this explicitly rather than use fill_in, since the shim for date fields in Firefox creates a separate input
      dd = find('.tracker-event_date input')
      if dd[:type] == 'date'
        dd.send_keys '2125-10-01'
      else
        dd.set ''
        dd.set '10/01/2125'
      end
      click_button 'Update Tracker'
    end

    expect(page).to have_css '.master-expander', wait: 10
    expect(page).to have_css "##{h} " + 'tbody[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"] span.record-meta', text: @user.email.to_s
    expect(page).to have_css "##{h} " + 'tbody[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"] .tracker-event_date', text: %r{10/0?1/2125}

    within "##{h} " + 'tbody[data-template="tracker-result-template"][data-tracker-protocol="' + protocol.name.downcase + '"]' do
      click_link 'show history'
    end

    # The previous item is there still
    expect(page).to have_css "##{h} " + 'tbody.tracker-history .tracker-history-sub_process_name', text: /#{sp_orig.name}/i
    expect(page).to have_css "##{h} " + 'tbody.tracker-history .tracker-history-event_name', text: /#{pe_orig.name}/i
    expect(page).to have_css "##{h} " + 'tbody.tracker-history .tracker-history-sub_process_name', text: /#{sp.name}/i
    expect(page).to have_css "##{h} " + 'tbody.tracker-history .tracker-history-event_name', text: /#{pe.name}/i
  end

  after(:all) do
  end
end
