# frozen_string_literal: true

require 'rails_helper'

# Purpose: Regression coverage for issue #1459, ensuring a persisted unknown
# REDCap project data option does not prevent listing and is shown on edit.
describe 'admin REDCap project with an unknown data option', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include Redcap::RedcapSupport
  include FeatureSupport

  before(:example) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    make_an_admin
    create_admin_matching_user
    setup_redcap_project_admin_configs

    # Close any extra windows from previous tests
    if respond_to?(:windows)
      extra_window_count = windows.length - 1
      extra_window_count.times { windows.last.close }
    end

    admin_sign_in_with_2fa
  end

  it 'lists the project and shows its unrecognized data option when opened for issue #1459' do
    project = Redcap::ProjectAdmin.active.first
    unknown_key = 'unknown_data_option'
    persisted_value = 'persisted-secret-value-1459'
    persisted_options = YAML.safe_load(project.options.to_s, permitted_classes: [Symbol], aliases: true) || {}
    persisted_options = persisted_options.deep_stringify_keys
    persisted_options['data_options'] ||= {}
    persisted_options['data_options'][unknown_key] = persisted_value
    project.update_column(:options, persisted_options.to_yaml)

    visit '/redcap/project_admins'
    finish_page_loading

    expect(page).to have_css("#admin-item-#{project.id}", wait: 10)

    within "#admin-item-#{project.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.admin-edit-form', wait: 10)
    finish_page_loading
    expect(page).to have_content(project.name, wait: 10)
    expect(page).to have_css('.config-error-block', visible: true, wait: 10)

    within '.config-error-block' do
      expect(page).to have_content('configuration errors')
      expect(page).to have_content(unknown_key)
      expect(page).not_to have_content(persisted_value)
    end
  end
end
