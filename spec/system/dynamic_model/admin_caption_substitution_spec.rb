# frozen_string_literal: true

# System regression spec for dynamic-model header_caption substitutions introduced by issue #1594.
# It verifies a configured caption can use ignore_missing and a formatter through the browser UI.

require 'rails_helper'

describe 'dynamic model header_caption substitutions', js: true, driver: $browser_driver do # rubocop:disable Style/GlobalVars
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    change_setting('AllowDynamicMigrations', true)
    SetupHelper.feature_setup

    @admin, = create_admin
    create_data_set_outside_tx
    expect(@master).not_to be_nil

    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email
    @app_type = @user.app_type
    @master.current_user = @user

    table_name = 'issue_caption_substitutions'
    DynamicModel.active.where(table_name:).find_each { |definition| definition.disable!(@admin) }
    @dynamic_model = DynamicModel.create!(
      current_admin: @admin,
      name: 'Issue 1594 Caption Substitutions',
      table_name:,
      schema_name: 'dynamic_test',
      category: :details,
      field_list: 'description',
      primary_key_name: 'id',
      foreign_key_name: 'master_id',
      options: <<~YAML
        default:
          label: Caption Substitution
          fields:
            - description
          view_options:
            header_caption: '{{missing_caption::ignore_missing}} {{description::uppercase}}'
      YAML
    )
    @resource_name = :dynamic_model__issue_caption_substitutions
    setup_access @resource_name, user: @user, app_type: @app_type
    @caption_text = "issue 1594 caption #{SecureRandom.hex(3)}"
    @dynamic_model.implementation_class.create!(
      master: @master,
      description: @caption_text,
      current_user: @user
    )
    SetupHelper.reload_configs
    Rails.application.routes_reloader.reload!
  end

  after(:all) do
    @dynamic_model&.disable!(@admin) if @dynamic_model&.persisted?
    change_setting('AllowDynamicMigrations', false)
  end

  before(:each) do
    validate_setup
    login
  end

  it 'renders a formatted header caption with a missing tag omitted' do
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    dismiss_modal
    expect(page).to have_css("#master-#{@master.id}")
    expand_master_record_and_tab(master_id: @master.id, tab_name: 'details')
    caption_selector = "[data-sub-list='#{@resource_name}'] [data-human-name*='#{@caption_text.upcase}']"
    expect(page).to have_css(caption_selector, wait: 10)
    expect(page).not_to have_css("[data-sub-list='#{@resource_name}'] [data-human-name*='(?)']")
  end
end
