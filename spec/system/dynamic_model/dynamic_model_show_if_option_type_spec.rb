# frozen_string_literal: true

require 'rails_helper'

# Tests for GitHub issue #1254: in show (read-only) mode, show_if rules correctly hide
# the caption-before element of a field, but the read-only field value
# (.result-field-container) remains visible for dynamic models that use option types
# selected via a custom `_configurations.option_type_attr_name` (as generated for
# Redcap projects). The tests verify that select-style and boolean field values are
# hidden when their show_if conditions are not met, and remain visible when they are met.
describe 'dynamic model show_if in show mode with option types', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport
  include TestShowIfOptionTypeDmSupport
  include DynamicModelExpectationsSupport

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    create_admin

    ms = Master.no_temporary_masters

    if ms.none? || ms.first&.id.to_i < 1
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
    expect(@user.two_factor_auth_disabled).to be_truthy
  end

  before(:all) do
    @resource_name = :dynamic_model__test_show_if_option_types
    set_up_feature
    setup_show_if_option_type_dm

    setup_access @resource_name, user: @user, app_type: @app_type
    # The master record panel templates require tracker access to render
    setup_access :trackers, user: @user, app_type: @app_type
    expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
    Rails.application.routes_reloader.reload!

    # Record where the show_if conditions are NOT met (visit_name != '1'):
    # form_label and flag_field should be hidden in show mode
    @hidden_fields_rec = create_option_type_record(visit_name: '2')

    # Record where the show_if conditions ARE met (visit_name == '1'):
    # form_label and flag_field should be visible in show mode
    @visible_fields_rec = create_option_type_record(visit_name: '1')
  end

  before :each do
    validate_setup
    login
  end

  it 'hides select and boolean field values in show mode when show_if conditions are not met' do
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
    dismiss_modal

    expect(page).to have_css("#master-#{@master_id}")
    expect(page).not_to have_css('.alert')

    expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
    finish_page_loading
    finish_form_formatting

    expect(page).to have_css("#details-#{@master_id}")

    dm_form_mode :show
    expect_block.to have_show_form

    # Record where show_if conditions are not met (visit_name = '2')
    within option_type_record_block(@hidden_fields_rec) do
      # Unconditional fields remain visible
      expect_block.to have_input_field('event_type')
      expect_block.to have_input_field('visit_name')

      # The caption before the conditional field is hidden by the show_if rules
      expect_block.not_to have_caption_before('form_label')

      # Issue #1254: the read-only values must also be hidden
      # The select-style field value (is--select-field)
      expect_block.not_to have_input_field('form_label')
      # The boolean (checkbox) field value
      expect_block.not_to have_input_field('flag_field')
    end
  end

  it 'shows select and boolean field values in show mode when show_if conditions are met' do
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
    dismiss_modal

    expect(page).to have_css("#master-#{@master_id}")
    expect(page).not_to have_css('.alert')

    expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
    finish_page_loading
    finish_form_formatting

    expect(page).to have_css("#details-#{@master_id}")

    dm_form_mode :show
    expect_block.to have_show_form

    # Record where show_if conditions are met (visit_name = '1')
    within option_type_record_block(@visible_fields_rec) do
      expect_block.to have_input_field('event_type')
      expect_block.to have_input_field('visit_name')

      # The caption and both conditional field values are visible
      expect_block.to have_caption_before('form_label')
      expect_block.to have_input_field('form_label')
      expect_block.to have_input_field('flag_field')
    end
  end
end
