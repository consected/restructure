# frozen_string_literal: true

# Admin Dynamic Model: Details accordion block
#
# Tests that the dynamic model definition admin "Details" tab presents its
# definition sections as a Bootstrap accordion (panel-group) with five panels:
# fields (combining fields, field definitions, additional table columns, and
# activities), libraries, dialogs, views referencing database table, and field
# configs. All panels are collapsed by default so admins do not need to scroll
# past long sections to reach controls below.
#
# Also confirms that when the "fields" panel is expanded, the sortable
# "(drop here to remove)" trash target is visible with non-zero size and is
# able to receive a drag-and-drop event.
#
# Issue: https://github.com/consected/restructure/issues/1095

require 'rails_helper'

describe 'admin dynamic model details accordion', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  let(:dm) do
    DynamicModel.active.find { |d| d.table_or_view_ready? && d.field_list.present? } ||
      DynamicModel.active.find(&:table_or_view_ready?)
  end

  before do
    skip 'No active dynamic models with ready tables found' unless dm

    admin_sign_in_with_2fa
    visit '/admin/dynamic_models'
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end
    expect(page).to have_css('.nav-tabs', wait: 10)
    # Details tab is the default active tab
    expect(page).to have_css('#def-details-block', visible: true)
  end

  let(:accordion_id) { "dm-details-accordion-#{dm.id}" }

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

      # Activity-list wrappers are rendered inside panel bodies and are hidden while
      # their panel-collapse containers are collapsed.
      expect(page).to have_css("##{accordion_id} .activity-list-fields", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-libraries", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-dialogs", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-view-refs", visible: false)
      expect(page).to have_css("##{accordion_id} .activity-list-field-configs", visible: false)

      # All four sub-sections collapsed within the fields panel are not visible
      expect(page).not_to have_css('#field-list-outer-block', visible: true)
    end
  end

  it 'expands the fields panel to reveal field definitions, activities and the trash drop target' do
    within '#def-details-block' do
      find("a[data-toggle='collapse'][href='##{accordion_id}-fields-collapse']").click

      expect(page).to have_css(
        "##{accordion_id}-fields-collapse.panel-collapse.collapse.in", visible: true, wait: 5
      )

      # The labels for the four sub-sections are rendered inside the panel body
      panel = find("##{accordion_id}-fields-collapse")
      expect(panel).to have_content('field definitions')

      # The sortable block including (drop here to remove) trash target is now visible
      expect(page).to have_css('#field-list-outer-block', visible: true)
      expect(page).to have_css('#field-list-outer-block .make-sortable', visible: true)
      expect(page).to have_css('#field-list-outer-block .sortable-block-trash', visible: true)
    end

    rect = page.evaluate_script(<<~JS)
      (function(){
        var el = document.querySelector('#field-list-outer-block .sortable-block-trash');
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

      # Opening libraries should collapse the previously-open fields panel
      expect(page).to have_css(
        "##{accordion_id}-fields-collapse.panel-collapse.collapse:not(.in)", visible: false, wait: 5
      )
    end
  end
end
