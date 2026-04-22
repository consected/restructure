# frozen_string_literal: true

# Tests for GitHub Issue #1049: Admin Message Templates loses "Is a" field value
#
# The message_templates/_form.html.erb unconditionally overrides the selected value
# of the message_type and template_type select fields with the filter parameter value.
# After saving, the edit form re-renders with the filter value instead of the saved model value.
#
# These tests verify that:
# - The edit form shows the saved model value, not the filter value
# - The new form correctly pre-selects the filter value for blank objects

require 'rails_helper'

RSpec.describe Admin::MessageTemplatesController, type: :controller do
  render_views

  before(:each) do
    admin, = ControllerMacros.create_admin
    @request.env['devise.mapping'] = Devise.mappings[:admin]
    sign_in admin
    raise 'Admin not logged in' unless subject.current_admin

    @admin = admin
  end

  describe 'GET #edit' do
    it 'does not override saved message_type with filter value' do
      template = Admin::MessageTemplate.create!(
        name: 'test_message_type_filter',
        message_type: 'dialog',
        template_type: 'content',
        current_admin: @admin
      )

      get :edit, params: { id: template.id, filter: { message_type: 'plain' } }

      expect(response).to have_http_status(:ok)
      # The select should have "dialog" selected (the saved value), not "plain" (the filter value)
      expect(response.body).to have_selector('select[name="admin_message_template[message_type]"] option[selected]', text: 'dialog')
      expect(response.body).not_to have_selector('select[name="admin_message_template[message_type]"] option[selected]', text: 'plain')
    end

    it 'does not override saved template_type with filter value' do
      template = Admin::MessageTemplate.create!(
        name: 'test_template_type_filter',
        message_type: 'email',
        template_type: 'content',
        current_admin: @admin
      )

      get :edit, params: { id: template.id, filter: { template_type: 'layout' } }

      expect(response).to have_http_status(:ok)
      # The select should have "content" selected (the saved value), not "layout" (the filter value)
      expect(response.body).to have_selector('select[name="admin_message_template[template_type]"] option[selected]', text: 'content')
      expect(response.body).not_to have_selector('select[name="admin_message_template[template_type]"] option[selected]', text: 'layout')
    end
  end

  describe 'GET #new' do
    it 'pre-selects filter value for message_type on a new record' do
      get :new, params: { filter: { message_type: 'dialog' } }

      expect(response).to have_http_status(:ok)
      # On a new (blank) record, the filter value should be pre-selected
      expect(response.body).to have_selector('select[name="admin_message_template[message_type]"] option[selected]', text: 'dialog')
    end
  end
end
