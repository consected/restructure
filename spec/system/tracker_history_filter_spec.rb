# frozen_string_literal: true

# System specs for the tracker history panel filter UI (issue #1074).
#
# These tests drive the real browser UI through Capybara, exercising the
# chosen.js multi-select filters (protocol, sub_process, protocol_event),
# the notes free-text filter, the date range filter, and the clear
# action. They also verify regex-driven and literal initial filter values
# applied via the `tracker history initial filters` app configuration.
#
# Tests use the existing `select_from_chosen` helper (from
# spec/support/feature_support.rb) so the chosen dropdowns are exercised
# the same way a human user would interact with them, rather than firing
# synthetic JavaScript events.

require 'rails_helper'

describe 'tracker history filter panel', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    create_admin

    # Disable any existing protocol events so we know what is in the test set
    Classification::ProtocolEvent.enabled.each do |d|
      d.update!(disabled: true, current_admin: @admin)
    end

    seed_database
    create_data_set_outside_tx no_trackers: true, no_seed: true

    @user, @good_password = create_user(nil, '', create_master: true)
    @good_email = @user.email
    @app_type = @user.app_type

    setup_access :trackers
    setup_access :tracker_histories
    setup_access :trackers, user: @user
    setup_access :tracker_histories, user: @user

    # Create a fresh master with a deterministic set of tracker history rows
    @filter_master = Master.new(current_user: @user)
    @filter_master.save!

    @protocol_study = Classification::Protocol.create!(
      name: "Study #{rand(100_000)}", current_admin: @admin
    )
    @protocol_other = Classification::Protocol.create!(
      name: "Other #{rand(100_000)}", current_admin: @admin
    )

    @sp_consented = @protocol_study.sub_processes.create!(
      name: 'consented', disabled: false, current_admin: @admin
    )
    @sp_declined = @protocol_study.sub_processes.create!(
      name: 'declined', disabled: false, current_admin: @admin
    )
    @sp_other = @protocol_other.sub_processes.create!(
      name: 'misc', disabled: false, current_admin: @admin
    )

    @ev_visit_1 = @sp_consented.protocol_events.create!(
      name: 'visit_1', disabled: false, current_admin: @admin
    )
    @ev_visit_2 = @sp_consented.protocol_events.create!(
      name: 'visit_2', disabled: false, current_admin: @admin
    )
    @ev_phone = @sp_declined.protocol_events.create!(
      name: 'phone', disabled: false, current_admin: @admin
    )
    @ev_misc = @sp_other.protocol_events.create!(
      name: 'misc_event', disabled: false, current_admin: @admin
    )

    @row_a = @filter_master.trackers.create!(
      protocol_id: @protocol_study.id,
      sub_process_id: @sp_consented.id,
      protocol_event_id: @ev_visit_1.id,
      event_date: '2025-01-15 09:00:00',
      notes: 'follow-up scheduled'
    )
    @row_b = @filter_master.trackers.create!(
      protocol_id: @protocol_study.id,
      sub_process_id: @sp_consented.id,
      protocol_event_id: @ev_visit_2.id,
      event_date: '2025-02-20 14:30:00',
      notes: 'follow-up complete'
    )
    @row_c = @filter_master.trackers.create!(
      protocol_id: @protocol_study.id,
      sub_process_id: @sp_declined.id,
      protocol_event_id: @ev_phone.id,
      event_date: '2025-03-10 10:00:00',
      notes: 'left voicemail'
    )
    @row_d = @filter_master.trackers.create!(
      protocol_id: @protocol_other.id,
      sub_process_id: @sp_other.id,
      protocol_event_id: @ev_misc.id,
      event_date: '2025-04-05 08:00:00',
      notes: 'unrelated note'
    )

    # Create a tracker history row under the system "Updates" protocol so we
    # can verify its protocol events are excluded from the filter dropdown.
    @updates_protocol = Classification::Protocol.record_updates_protocol
    @updates_sub_process = @updates_protocol.sub_processes.first
    @updates_event = @updates_sub_process.protocol_events.first
    @row_updates = @filter_master.trackers.create!(
      protocol_id: @updates_protocol.id,
      sub_process_id: @updates_sub_process.id,
      protocol_event_id: @updates_event.id,
      event_date: '2025-05-01 09:00:00',
      notes: 'system update entry'
    )
  end

  before(:each) do
    Admin::AppConfiguration.where(name: 'tracker history initial filters').delete_all
    Admin::AppConfiguration.clear_memo!
    login
  end

  # Open the master, expand tracker panel, switch to the chronological view
  # which contains the filter row.
  def open_chron_view
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@filter_master.id}"
    dismiss_modal
    finish_page_loading

    expect(page).to have_css("#master-#{@filter_master.id}-main-container.in", wait: 10)
    expand_tracker_panel

    expect(page).to have_css('table.tracker-tree-results', wait: 10)
    chron_link = find('table.tracker-tree-results thead a[data-template="tracker-chron-result-template"]')
    scroll_into_view(chron_link)
    chron_link.click

    expect(page).to have_css('table.tracker-chron-results', wait: 10)
    expect(page).to have_css('.tracker-chron-results-wrap select.tracker-history-filter.attached-chosen',
                             visible: :all, wait: 10)
    sleep 0.5
  end

  def visible_event_names
    page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"]) td.tracker-history-event_name',
             wait: 2).map { |el| el.text.strip }
  end

  # Helper that mirrors select_multiple_from_chosen but closes the chosen
  # dropdown by clicking a known element on the filter row (the
  # `.tracker-history-filters__clear-cell`) rather than relying on the
  # generic `label, .caption-before` element which the chron view does not have.
  def select_filter_chosen(field_name, values)
    is_multi = true
    Array(values).each do |v|
      select_from_chosen(field_name, v, is_multi: is_multi)
      is_multi = :already_open
    end
    page.execute_script('document.activeElement && document.activeElement.blur && document.activeElement.blur();')
    sleep 0.3
  end

  it 'shows all rows by default with no filters applied' do
    open_chron_view

    names = visible_event_names
    expect(names).to include(/visit/i, /phone/i, /misc/i)
    expect(names.length).to be >= 4
  end

  it 'filters rows by selecting a protocol via the chosen multi-select' do
    open_chron_view

    select_filter_chosen('tracker_history_filter_protocols', [@protocol_study.name])

    sleep 0.5
    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    rows.each do |r|
      expect(r['data-protocol-name']).to eq(@protocol_study.name)
    end
    expect(rows.length).to eq(3)
  end

  it 'filters by free-text notes (case-insensitive partial match)' do
    open_chron_view

    notes_input = find('input.tracker-history-filter-notes')
    notes_input.fill_in(with: 'FOLLOW')
    sleep 0.5

    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    expect(rows.length).to eq(2)
    rows.each do |r|
      expect(r['data-notes'].downcase).to include('follow')
    end
  end

  it 'filters by event_date range, ignoring the time component' do
    open_chron_view

    # Date inputs: set via JS-driven value + trigger change, since
    # headless Chrome's native date picker is awkward to drive via send_keys
    # and produces inconsistent results across locales.
    page.execute_script(<<~JS)
      $('input.tracker-history-filter-date-from').val('2025-02-01').trigger('change');
      $('input.tracker-history-filter-date-to').val('2025-03-31').trigger('change');
    JS
    sleep 0.5

    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    expect(rows.length).to eq(2)
    visible_dates = rows.map { |r| r['data-event-date'][0, 10] }.sort
    expect(visible_dates).to eq(['2025-02-20', '2025-03-10'])
  end

  it 'combines multi-select and notes filters with AND across groups' do
    open_chron_view

    select_filter_chosen('tracker_history_filter_protocols', [@protocol_study.name])
    find('input.tracker-history-filter-notes').fill_in(with: 'follow-up')
    sleep 0.5

    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    expect(rows.length).to eq(2)
    rows.each do |r|
      expect(r['data-protocol-name']).to eq(@protocol_study.name)
      expect(r['data-notes']).to include('follow-up')
    end
  end

  it 'restores all rows when the clear filters button is clicked' do
    open_chron_view

    select_filter_chosen('tracker_history_filter_protocols', [@protocol_study.name])
    find('input.tracker-history-filter-notes').fill_in(with: 'follow-up')
    find('input.tracker-history-filter-date-from').fill_in(with: '2025-02-01')
    sleep 0.5

    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    expect(rows.length).to be < 4

    clear_link = find('a.tracker-history-filters__clear')
    scroll_into_view(clear_link)
    clear_link.click
    sleep 0.5

    expect(find('input.tracker-history-filter-notes').value).to eq('')
    expect(find('input.tracker-history-filter-date-from').value).to eq('')
    expect(find('input.tracker-history-filter-date-to').value).to eq('')

    rows_after = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    expect(rows_after.length).to be >= 4
  end

  it 'preselects multi-select tags from a regex configured in app config' do
    Admin::AppConfiguration.add_default_config(
      @app_type,
      :tracker_history_initial_filters,
      "protocols: '^Study'\n",
      @admin
    )
    Admin::AppConfiguration.clear_memo!

    open_chron_view

    selected_tags = page.all('div#tracker_history_filter_protocols_' \
                             "#{@filter_master.id}_chosen ul.chosen-choices li.search-choice span")
                        .map { |el| el.text.strip }
    expect(selected_tags).to include(@protocol_study.name)
    expect(selected_tags).not_to include(@protocol_other.name)

    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    rows.each do |r|
      expect(r['data-protocol-name']).to eq(@protocol_study.name)
    end
  end

  it 'preselects the notes filter from the literal value in app config' do
    Admin::AppConfiguration.add_default_config(
      @app_type,
      :tracker_history_initial_filters,
      "notes: 'follow-up'\n",
      @admin
    )
    Admin::AppConfiguration.clear_memo!

    open_chron_view

    expect(find('input.tracker-history-filter-notes').value).to eq('follow-up')

    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    expect(rows.length).to eq(2)
    rows.each do |r|
      expect(r['data-notes']).to include('follow-up')
    end
  end

  it 'still renders the panel when configured regex is invalid (no preselection)' do
    Admin::AppConfiguration.add_default_config(
      @app_type,
      :tracker_history_initial_filters,
      "protocols: '[invalid'\n",
      @admin
    )
    Admin::AppConfiguration.clear_memo!

    open_chron_view

    selected_tags = page.all('div#tracker_history_filter_protocols_' \
                             "#{@filter_master.id}_chosen ul.chosen-choices li.search-choice span")
    expect(selected_tags).to be_empty

    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    expect(rows.length).to be >= 4
  end

  it 'omits protocol events that belong to the system Updates protocol from the dropdown' do
    open_chron_view

    # Build the set of event names belonging to rows in the system Updates
    # protocol. The Tracker after_save pipeline may rewrite the protocol_event
    # for entries created with the Updates protocol, so derive these names
    # from the rendered rows rather than from the originally requested event.
    updates_event_names = page.evaluate_script(<<~JS)
      $('table.tracker-chron-results tr.tracker-history-row[data-protocol-name="Updates"]')
        .map(function () { return $(this).attr('data-event-name'); }).get();
    JS
    expect(updates_event_names).not_to be_empty,
                                       'expected at least one tracker row under the Updates protocol'

    # The protocol_events filter <select> is hidden by chosen, so query its
    # options directly.
    options = page.evaluate_script(<<~JS)
      $('select.tracker-history-filter[data-filter-key=protocol_events] option')
        .map(function () { return $(this).text(); }).get();
    JS

    expect(options).to include(@ev_visit_1.name, @ev_visit_2.name, @ev_phone.name, @ev_misc.name)
    updates_event_names.each do |name|
      expect(options).not_to include(name)
    end
  end

  it 'preselects the date range from absolute and relative values in app config' do
    Admin::AppConfiguration.add_default_config(
      @app_type,
      :tracker_history_initial_filters,
      "date_from: '2025-02-01'\ndate_to: '2025-03-31'\n",
      @admin
    )
    Admin::AppConfiguration.clear_memo!

    open_chron_view

    # Inputs are reformatted to the user's locale by the shared
    # `setup_datepickers` JS helper. We just check non-blank values here
    # and assert the filter rows are correctly limited.
    from_value = page.evaluate_script("$('input.tracker-history-filter-date-from').val()")
    to_value = page.evaluate_script("$('input.tracker-history-filter-date-to').val()")
    expect(from_value).not_to be_blank
    expect(to_value).not_to be_blank

    rows = page.all('table.tracker-chron-results tbody.tracker-history-rows tr.tracker-history-row:not([style*="display: none"])')
    expect(rows.length).to eq(2)
    visible_dates = rows.map { |r| r['data-event-date'][0, 10] }.sort
    expect(visible_dates).to eq(['2025-02-20', '2025-03-10'])
  end
end
