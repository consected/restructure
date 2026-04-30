# frozen_string_literal: true

# Admin External Identifier: Details accordion block
#
# Tests that the external identifier definition admin "Details" tab presents
# its definition sections as a Bootstrap accordion (panel-group) with five
# panels: fields (combining fields and activities), libraries, dialogs, views
# referencing database table, and field configs - matching the dynamic model
# Details tab. All panels are collapsed by default.
#
# Also confirms that when the "fields" panel is expanded, the sortable
# "(drop here to remove)" trash target is visible with non-zero size, and that
# the user access controls summary is rendered above the accordion.
#
# Issue: https://github.com/consected/restructure/issues/1095

require 'rails_helper'

describe 'admin external identifier details accordion', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  let(:external_identifier) do
    ExternalIdentifier.active.find { |ei| ei.enabled? && ei.table_or_view_ready? } ||
      ExternalIdentifier.active.find(&:enabled?)
  end

  before do
    skip 'No active external identifiers found' unless external_identifier

    admin_sign_in_with_2fa
    visit '/admin/external_identifiers'
    finish_page_loading

    within "#admin-item-#{external_identifier.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)
    expect(page).to have_css('#def-details-block', visible: true)
  end

  let(:accordion_id) { "ei-details-accordion-#{external_identifier.id}" }

  it 'renders the Details panels and auto-expands UAC when warnings are present' do
    within '#def-details-block' do
      expect(page).to have_css("##{accordion_id}.panel-group")

      %w[uac fields libraries dialogs view-refs field-configs].each do |panel|
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

      %w[fields libraries dialogs view-refs field-configs].each do |panel|
        expect(page).not_to have_css("##{accordion_id}-#{panel}-collapse.in", visible: true)
      end

      expect(page).to have_css("##{accordion_id} .activity-list-fields", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-libraries", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-dialogs", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-view-refs", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-field-configs", visible: false)

      expect(page).not_to have_css('#external-identifier-field-list-outer-block', visible: true)
    end
  end

  it 'renders the user access controls section in the UAC accordion panel' do
    within '#def-details-block' do
      expect(page).to have_css("a[data-toggle='collapse'][href='##{accordion_id}-uac-collapse']")
      expect(page).to have_css("##{accordion_id}-uac-collapse .common-def-panel--uacs", visible: false)
    end
  end

  it 'expands the fields panel to reveal fields, activities and the trash drop target' do
    within '#def-details-block' do
      find("a[data-toggle='collapse'][href='##{accordion_id}-fields-collapse']").click

      expect(page).to have_css(
        "##{accordion_id}-fields-collapse.panel-collapse.collapse.in", visible: true, wait: 5
      )

      panel = find("##{accordion_id}-fields-collapse")
      expect(panel).to have_content('fields')

      expect(page).to have_css('#external-identifier-field-list-outer-block', visible: true)
      expect(page).to have_css('#external-identifier-field-list-outer-block .make-sortable', visible: true)
      expect(page).to have_css('#external-identifier-field-list-outer-block .sortable-block-trash', visible: true)
    end

    rect = page.evaluate_script(<<~JS)
      (function(){
        var el = document.querySelector('#external-identifier-field-list-outer-block .sortable-block-trash');
        if (!el) return null;
        var r = el.getBoundingClientRect();
        return { width: r.width, height: r.height };
      })();
    JS
    expect(rect).not_to be_nil
    expect(rect['width']).to be > 0
    expect(rect['height']).to be > 0
  end

  it 'opens panels exclusively (Bootstrap accordion behaviour)' do
    within '#def-details-block' do
      find("a[data-toggle='collapse'][href='##{accordion_id}-fields-collapse']").click
      expect(page).to have_css("##{accordion_id}-fields-collapse.in", visible: true, wait: 5)

      find("a[data-toggle='collapse'][href='##{accordion_id}-libraries-collapse']").click
      expect(page).to have_css("##{accordion_id}-libraries-collapse.in", visible: true, wait: 5)

      expect(page).to have_css(
        "##{accordion_id}-fields-collapse.panel-collapse.collapse:not(.in)", visible: false, wait: 5
      )
    end
  end
end
