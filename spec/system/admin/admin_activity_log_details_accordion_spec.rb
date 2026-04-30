# frozen_string_literal: true

# Admin Activity Log: Details accordion block
#
# Tests that the activity log admin Details tab presents its major sections as
# a Bootstrap accordion (panel-group) with eight panels:
# activities, all fields, libraries, embeds, references, file filters,
# views referencing database table, and field configs.
#
# Also verifies all panels are collapsed by default and that opening one panel
# collapses a previously-open panel.
#
# Issue: https://github.com/consected/restructure/issues/1095

require 'rails_helper'

describe 'admin activity log details accordion', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  let(:activity_log) do
    ActivityLog.active.find(&:enabled?)
  end

  before do
    skip 'No active activity logs found' unless activity_log

    admin_sign_in_with_2fa
    visit '/admin/activity_logs'
    finish_page_loading

    within "#admin-item-#{activity_log.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)
    expect(page).to have_css('#def-details-block', visible: true)
  end

  let(:accordion_id) { "al-details-accordion-#{activity_log.id}" }

  it 'renders the Details sections and auto-expands UAC when warnings are present' do
    within '#def-details-block' do
      expect(page).to have_css("##{accordion_id}.panel-group")

      %w[uac activities all-fields libraries embeds references file-filters view-refs field-configs].each do |panel|
        expect(page).to have_css(
          "##{accordion_id} a[data-toggle='collapse'][data-parent='##{accordion_id}']" \
          "[href='##{accordion_id}-#{panel}-collapse']"
        )
        expect(page).to have_css("##{accordion_id}-#{panel}-collapse.panel-collapse.collapse", visible: false)
      end

      uac_state = page.evaluate_script(<<~JS)
        (function(){
          var panel = document.querySelector('##{accordion_id}-uac-collapse');
          if (!panel) return null;
          var hasWarnings = panel.querySelectorAll('.text-warning, .text-info').length > 0;
          var isExpanded = panel.classList.contains('in');
          return { hasWarnings: hasWarnings, isExpanded: isExpanded };
        })();
      JS
      expect(uac_state).not_to be_nil
      expect(uac_state['isExpanded']).to eq(uac_state['hasWarnings'])

      %w[activities all-fields libraries embeds references file-filters view-refs field-configs].each do |panel|
        expect(page).not_to have_css("##{accordion_id}-#{panel}-collapse.in", visible: true)
      end

      expect(page).to have_css("##{accordion_id} .activity-list-section", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-all-fields", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-libraries", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-embeds", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-references", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-file-filters", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-view-refs", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-field-configs", visible: false)
    end
  end

  it 'expands the activities panel to reveal activities details' do
    within '#def-details-block' do
      find("a[data-toggle='collapse'][href='##{accordion_id}-activities-collapse']").click

      expect(page).to have_css(
        "##{accordion_id}-activities-collapse.panel-collapse.collapse.in", visible: true, wait: 5
      )

      panel = find("##{accordion_id}-activities-collapse")
      expect(panel).to have_content('Add a new')
      expect(panel).to have_content('[activity_name]:')
    end
  end

  it 'opens panels exclusively (Bootstrap accordion behaviour)' do
    within '#def-details-block' do
      find("a[data-toggle='collapse'][href='##{accordion_id}-activities-collapse']").click
      expect(page).to have_css("##{accordion_id}-activities-collapse.in", visible: true, wait: 5)

      find("a[data-toggle='collapse'][href='##{accordion_id}-all-fields-collapse']").click
      expect(page).to have_css("##{accordion_id}-all-fields-collapse.in", visible: true, wait: 5)

      expect(page).to have_css(
        "##{accordion_id}-activities-collapse.panel-collapse.collapse:not(.in)", visible: false, wait: 5
      )
    end
  end
end
