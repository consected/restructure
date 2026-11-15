# frozen_string_literal: true

# System spec for GitHub issue #1167
#
# Purpose: verify that a dynamic model field configured with `edit_as: field_type: notes`
# and `format: plain` preserves newlines in view (show) mode as <br> elements.
#
# The Bug: when the app config `notes_field_format` is set to `markdown`, the Handlebars
# template `search_results_notes_block` takes the markdown rendering path for ALL notes
# fields, including those with an explicit `format: plain` field option.  Markdown does
# not convert single `\n` to `<br>`, so multi-line plain text appears on one line.
#
# This spec is intentionally RED (failing) until the fix is implemented in
# app/views/common_templates/_common_parts.html.erb to check for `format: plain`
# *before* falling through to the app-config markdown check.

require 'rails_helper'

describe 'notes field with format: plain displays newlines', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('AllowDynamicMigrations', true)

    create_admin

    ms = Master.no_temporary_masters
    if ms.none? || ms.first.nil? || ms.first.id < 1
      create_data_set_outside_tx
      @master ||= ms.first
      @master_id ||= @master.id
    else
      @master = ms.first
      @master_id = @master.id
    end

    expect(@master_id).to be > 0

    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email
    @app_type = @user.app_type
    expect(@app_type).not_to be nil
    expect(@user.two_factor_setup_required?).to be_falsey
  end

  def setup_notes_plain_dm
    DynamicModel.active.where(table_name: 'test_notes_plain_fields').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestNotesPlainField) if defined? DynamicModel::TestNotesPlainField

    dm_options = <<~YAML
      _configurations: {}

      default:
        field_options:
          details:
            edit_as:
              field_type: notes
            format: plain
          notes_markdown:
            edit_as:
              field_type: notes
            format: markdown
        labels:
          details: Details
          notes_markdown: Notes Markdown
    YAML

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test notes plain fields',
                              schema_name: 'dynamic_test',
                              table_name: 'test_notes_plain_fields',
                              category: :details,
                              options: dm_options,
                              field_list: 'details notes_markdown',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id'

    dm.current_admin = @admin
    dm.update_tracker_events

    setup_access :dynamic_model__test_notes_plain_fields, user: @user

    dm
  end

  describe 'notes field with format: plain' do
    before(:all) do
      set_up_feature
      @notes_dm = setup_notes_plain_dm

      # Force model regeneration after table creation via AllowDynamicMigrations
      @notes_dm.force_regenerate = true
      @notes_dm.generate_model
      @notes_dm.add_master_association

      DynamicModel.routes_load

      # Set the app config 'notes field format' to 'markdown' to trigger the bug:
      # with this setting active, the Handlebars template takes the markdown rendering
      # path for all notes fields, even those with field-level format: plain.
      # Use the string form with spaces as that is how the config name is stored.
      add_app_config @app_type, 'notes field format', 'markdown'

      Rails.application.routes_reloader.reload!
    end

    before(:each) do
      validate_setup
      login
    end

    # This test is RED (failing) until the fix is applied.
    # The fix should cause `format: plain` on a field to override the app config
    # `notes_field_format: markdown`, so that newlines are rendered as <br> elements.
    it 'shows newlines as <br> elements for a plain-format field even when app config notes_field_format is markdown' do
      multiline_text = "line one\nline two\nline three"

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      expand_master_record_tab('details')
      finish_page_loading

      new_button_selector = '.details-item-type-dynamic-model--test-notes-plain-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_selector, wait: 10)

      new_button = find(new_button_selector, wait: 10)
      scroll_into_view(new_button)
      new_button.click
      finish_page_loading

      expect(page).to have_css('form.new_dynamic_model_test_notes_plain_field', wait: 10)
      finish_form_formatting

      fill_in_field('details', multiline_text)

      within('form.new_dynamic_model_test_notes_plain_field') do
        click_on 'Save'
      end

      finish_page_loading

      # After saving, the record should display in show mode.
      # For a field with format: plain, newlines must render as <br> elements
      # (via the nl2br path in pretty_string).
      #
      # FAILS initially: the app config markdown path is taken instead of the
      # field-level plain path, so markdown_html is used and single \n is lost.
      #
      # NOTE: <br> elements have zero dimensions so Capybara's default visibility
      # check considers them "not displayed". Use visible: false to detect their
      # presence in the DOM regardless of display geometry.
      expect(page).to have_css('.notes-block .notes-text br', visible: false, wait: 15),
                      'Expected plain-format notes field to render newlines as <br> elements, ' \
                      'but no <br> was found. This indicates the markdown rendering path was ' \
                      'used instead of the plain text path (issue #1167).'
    end
  end
end
