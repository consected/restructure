# frozen_string_literal: true

require 'rails_helper'

# Tests for GitHub issue #1256: in edit mode, show_if rules must use the correct
# option type's rule set for dynamic models configured with a custom
# _configurations.option_type_attr_name (e.g. instrument_type, as generated for
# Redcap projects).
#
# The dynamic model has two option types with DELIBERATELY DIFFERENT show_if rules:
#   type_a: cond_field visible only when trigger_field == 'show_in_a'
#   type_b: cond_field visible only when trigger_field == 'show_in_b'
#
# The critical test opens a type_b record for editing, then sets trigger_field to
# 'show_in_a' and asserts cond_field remains hidden. If the JS were applying type_a
# rules to a type_b record (the bug), cond_field would incorrectly become visible.
describe 'dynamic model show_if in edit mode with custom option_type_attr_name', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport
  include TestShowIfEditOptTypeDmSupport
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
    @resource_name = :dynamic_model__test_show_if_edit_opt_types
    set_up_feature
    setup_show_if_edit_opt_type_dm

    setup_access @resource_name, user: @user, app_type: @app_type
    # The master record panel templates require tracker access to render
    setup_access :trackers, user: @user, app_type: @app_type
    expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
    Rails.application.routes_reloader.reload!

    # A type_b record with no trigger value set (cond_field hidden initially)
    @type_b_rec = create_edit_opt_type_record(instrument_type: 'type_b', trigger_field: nil)

    # A type_a record with no trigger value set (cond_field hidden initially)
    @type_a_rec = create_edit_opt_type_record(instrument_type: 'type_a', trigger_field: nil)
  end

  before :each do
    validate_setup
    login
  end

  # The central regression test for #1256:
  # When editing a type_b record, only the type_b show_if rule ('show_in_b') must
  # control cond_field visibility. Setting trigger_field to the type_a trigger value
  # ('show_in_a') must NOT show cond_field — that would indicate the wrong rule set
  # is being applied.
  it 'applies type_b show_if rules (not type_a rules) when editing a type_b record' do
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
    dismiss_modal

    expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
    expect_master_to_have_expanded(@master_id)
    finish_page_loading
    finish_form_formatting

    # Open the type_b record for editing
    dm_form_mode :show
    expect_block.to have_show_form

    record_block = edit_opt_type_show_block(@type_b_rec)
    edit_form = click_edit_button_within_target(record_block)
    dm_form_mode :edit

    within(edit_form) do
      # Initially cond_field is hidden (trigger_field is blank)
      expect_block.not_to have_input_field('cond_field')

      # Set trigger_field to the type_a value — must NOT show cond_field on a type_b record.
      # This is the exact failure mode for #1256: if JS applies type_a rules here,
      # cond_field would incorrectly become visible.
      fill_in_field 'trigger_field', 'show_in_a'
      expect_block.not_to have_input_field('cond_field')

      # Set trigger_field to the type_b value — cond_field must now become visible.
      fill_in_field 'trigger_field', 'show_in_b'
      expect_block.to have_input_field('cond_field')

      # Clearing the trigger should hide cond_field again.
      fill_in_field 'trigger_field', ''
      expect_block.not_to have_input_field('cond_field')
    end
  end

  # Sanity check: type_a rules work correctly on a type_a record.
  it 'applies type_a show_if rules when editing a type_a record' do
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
    dismiss_modal

    expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
    expect_master_to_have_expanded(@master_id)
    finish_page_loading
    finish_form_formatting

    dm_form_mode :show
    expect_block.to have_show_form

    record_block = edit_opt_type_show_block(@type_a_rec)
    edit_form = click_edit_button_within_target(record_block)
    dm_form_mode :edit

    within(edit_form) do
      # Initially hidden
      expect_block.not_to have_input_field('cond_field')

      # type_b trigger value must NOT show cond_field on a type_a record
      fill_in_field 'trigger_field', 'show_in_b'
      expect_block.not_to have_input_field('cond_field')

      # type_a trigger value must show cond_field
      fill_in_field 'trigger_field', 'show_in_a'
      expect_block.to have_input_field('cond_field')
    end
  end
end
