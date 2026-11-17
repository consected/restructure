# frozen_string_literal: true

# Message Template admin Details tab: configuration summary.
#
# Verifies the Details tab (added alongside the Versions tab for GitHub Issue
# #1346) presents a useful summary of what a message template configures,
# based on the categories documented in
# docs/admin_reference/message_templates/0_introduction.md: message
# notifications (layout/content), user account notifications, dialog
# templates, public/private info pages, UI templates, and HTML markup
# snippets.

require 'rails_helper'

describe 'admin message template details tab', js: true, driver: $browser_driver do
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
    @created_message_templates = []
  end

  after(:each) do
    @created_message_templates.each do |mt|
      mt.update(disabled: true, current_admin: @admin) if mt.persisted?
    end
  end

  def open_details_tab(message_template)
    @created_message_templates << message_template

    visit '/admin/message_templates'
    finish_page_loading

    within "#admin-item-#{message_template.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.admin-options-ref-block .nav-tabs', wait: 10)
    expect(page).to have_css('#def-details-block', visible: true)
  end

  it 'identifies an email layout template and flags a missing {{main_content}} placeholder' do
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: "layout_missing_main_content_#{SecureRandom.hex(4)}",
      category: 'test',
      message_type: :email,
      template_type: :layout,
      template: '<html><body>no placeholder here</body></html>'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('Message Notification')
      expect(page).to have_content('layout')
      expect(page).to have_content('Missing')
      expect(page).to have_content('{{main_content}}')
    end
  end

  it 'identifies an email layout template with a valid {{main_content}} placeholder' do
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: "layout_with_main_content_#{SecureRandom.hex(4)}",
      category: 'test',
      message_type: :email,
      template_type: :layout,
      template: '<html><body>{{main_content}}</body></html>'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('Contains')
      expect(page).to have_content('{{main_content}}')
    end
  end

  it 'identifies a known user account notification template' do
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: 'server password reset instructions',
      category: 'test',
      message_type: :email,
      template_type: :content,
      template: 'Reset your password: {{reset_url}}'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('user account notification')
    end
  end

  it 'identifies a dialog template' do
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: "some_help_dialog_#{SecureRandom.hex(4)}",
      category: 'test',
      message_type: :dialog,
      template_type: :content,
      template: '<p>Some helpful instructions</p>'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('Dialog Template')
    end
  end

  it 'identifies a public info page and shows its path' do
    slug = "public_info_page_#{SecureRandom.hex(4)}"
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: slug,
      category: 'public',
      message_type: :dialog,
      template_type: :content,
      template: '<p>Public info content</p>'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('public info page')
      expect(page).to have_content("/info_pages/#{slug.parameterize}")
    end
  end

  it 'identifies a private info page and shows its namespaced path' do
    slug = "private_info_page_#{SecureRandom.hex(4)}"
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: slug,
      category: 'study-category - info page',
      message_type: :dialog,
      template_type: :content,
      template: '<p>Private info content</p>'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('private info page')
      expect(page).to have_content("/info_pages/study-category__#{slug.parameterize}")
    end
  end

  it 'identifies a documented UI template by name' do
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: 'ui first login',
      category: 'ui',
      message_type: :plain,
      template_type: :content,
      template: '<p>Welcome!</p>'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('UI Template')
      expect(page).to have_content('ui first login')
    end
  end

  it 'identifies an undocumented UI template purely by its "ui " name prefix' do
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: "ui some new feature block #{SecureRandom.hex(4)}",
      category: 'ui',
      message_type: :plain,
      template_type: :content,
      template: '<p>New feature help text</p>'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('UI Template')
      expect(page).to have_content('not in the currently documented list')
    end
  end

  it 'identifies a UI template using the dialog (markdown) editor, not a generic dialog template' do
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: "ui markdown feature block #{SecureRandom.hex(4)}",
      category: 'ui',
      message_type: :dialog,
      template_type: :content,
      template: '**Some markdown help text**'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('UI Template')
      expect(page).to have_content('markdown')
      expect(page).not_to have_content('instructive info block within dynamic definition forms')
    end
  end

  it 'identifies a page CSS HTML markup snippet' do
    mt = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: 'ui page css - test_app_type',
      category: 'ui',
      message_type: :plain,
      template_type: :content,
      template: 'body { color: red; }'
    )

    open_details_tab(mt)

    within '#def-details-block' do
      expect(page).to have_content('HTML Markup Snippet')
      expect(page).to have_content('test_app_type')
    end
  end
end
