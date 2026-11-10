# frozen_string_literal: true

# Activity Log admin Details tab: synced-fields panel and activities annotation.
#
# For issue #1445 (problem 2). Verifies, through the real accordion UI rather
# than just rendered HTML, that the "synced fields" panel added to the
# activity log Details tab surfaces fields shared with the parent item type
# (via Dynamic::ActivityLogImplementer.fields_to_sync), and that the same
# field is annotated at its point of use in the "activities" panel's field
# list.
#
# Uses a definition with a genuine `extra_log_types:` entry (matching the
# original bug report's shape - an extra log type explicitly listing a field
# that collides with the parent item type), rather than a traditional
# field_list-only activity log: clicking an activity name in the admin UI
# searches the YAML editor text for a literal "name:" key
# (app/assets/javascripts/admin/activity_logs/admin_edit_form.js), which only
# exists for genuine extra_log_types entries - the auto-injected :primary /
# :blank_log virtual entries used by field_list-only logs have no such text
# to find, and clicking them is a pre-existing, unrelated UI issue.

require 'rails_helper'

describe 'admin activity log details tab synced fields', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    change_setting('TwoFactorAuthDisabledForUser', true)
    make_an_admin
  end

  before(:each) do
    admin_sign_in_with_2fa

    # "data" collides with PlayerContact's own "data" attribute, so fields_to_sync == ["data"].
    rec_type = 'system_spec_appt'
    table_name = "activity_log_player_contact_#{rec_type}s"

    gs = Classification::GeneralSelection.find_or_initialize_by(item_type: 'player_contacts_type', value: rec_type)
    gs.update!(name: 'System Spec Appt', create_with: true, lock: true, current_admin: @admin) unless gs.admin

    ActiveRecord::Base.connection.schema_cache.clear!
    TableGenerators.activity_logs_table(table_name, 'player_contacts', true, 'data', 'notes')

    @activity_log = ActivityLog.create!(
      name: table_name,
      item_type: 'player_contact',
      rec_type:,
      action_when_attribute: 'created_at',
      extra_log_types: "appointment:\n  label: Appointment\n  fields:\n    - data\n    - notes\n",
      current_admin: @admin
    )
    @activity_log.update_tracker_events

    expect(@activity_log.implementation_class.fields_to_sync).to eq(['data'])
  end

  def open_details_tab(activity_log)
    visit '/admin/activity_logs'
    finish_page_loading

    within "#admin-item-#{activity_log.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('#def-details-block .al-details-accordion', wait: 10)
  end

  it 'shows the synced "data" field in a dedicated panel, and annotated within the activities panel' do
    open_details_tab(@activity_log)

    within '#def-details-block' do
      find("[id$='-synced-fields-heading'] a").click

      within '.al-synced-fields' do
        expect(page).to have_css('.al-synced-fields__parent-type', text: 'player_contact', wait: 5)
        expect(page).to have_css('.al-synced-fields__item', text: 'data')
        expect(page).to have_content('hidden from activity forms')
      end

      find("[id$='-activities-heading'] a").click
      # Wait for the Bootstrap accordion expand transition to finish before interacting with
      # nested content - clicking too early can race with the CSS collapse animation.
      expect(page).to have_css("[id$='-activities-collapse'].in", wait: 5)

      # Each activity's field list is itself collapsed until its name is clicked
      # (see app/assets/javascripts/admin/activity_logs/admin_edit_form.js).
      find('span.activity-list-name', text: 'appointment', exact_text: true).click

      expect(page).to have_css('.activity-list-activity-fields__item--synced', text: /data/, wait: 5)
      expect(page).to have_content('synced from parent')
    end
  end
end
