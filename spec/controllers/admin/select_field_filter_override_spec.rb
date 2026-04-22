# frozen_string_literal: true

# Tests for GitHub Issue #1050: Admin forms override saved select field values with filter params
#
# Several admin forms unconditionally override select field values with the active
# filter parameter, causing saved values to revert when re-editing after save.
# The fix is to add a `.blank?` guard so the filter only pre-selects on new/blank records.
#
# Affected templates:
#   - app/views/admin/common_templates/form/_fields.html.erb (line 50) — tested here
#     via Admin::ConfigLibrariesController, which renders select fields through _fields.html.erb
#     for fields that have a matching `*_options` helper (e.g. `format` → `format_options`).
#
#   - app/views/common_templates/edit_fields/_respond_to_options.html.erb (line 4) —
#     same bug pattern as _fields.html.erb line 50.
#
#   - app/views/admin/app_configurations/_form.html.erb (lines 16, 24) —
#     the `name` field bug is dead code (select_item_type not passed to big_select_field),
#     and the `role_name` field bug is dead code (role_name not in filters_on).
#     These are code-quality issues to fix but cannot be demonstrated with failing tests.
#
# These tests verify that:
#   - When a record already has a saved value and filter_params_hash matches,
#     the saved value is preserved (filter does NOT override it).
#   - When a record is new (field is blank) and filter_params_hash matches,
#     the filter value IS applied (pre-selection works for new records).

require 'rails_helper'

RSpec.describe Admin::ConfigLibrariesController, type: :controller do
  render_views

  before(:each) do
    admin, = ControllerMacros.create_admin
    @request.env['devise.mapping'] = Devise.mappings[:admin]
    sign_in admin
    raise 'Admin not logged in' unless subject.current_admin

    @admin = admin
  end

  describe 'GET #edit' do
    it 'does not override saved format with filter value' do
      library = Admin::ConfigLibrary.create!(
        name: "test_filter_guard_#{rand(100_000)}",
        category: 'test',
        format: 'yaml',
        options: 'test: true',
        current_admin: @admin
      )

      get :edit, params: { id: library.id, filter: { format: 'html' } }

      expect(response).to have_http_status(:ok)
      # The select should have 'yaml' selected (the saved value), not 'html' (the filter value)
      expect(response.body).to have_selector(
        'select#admin_config_library_format option[selected]', text: 'yaml'
      )
      expect(response.body).not_to have_selector(
        'select#admin_config_library_format option[selected]', text: 'html'
      )
    end
  end

  describe 'GET #new' do
    it 'pre-selects filter value for format on a new record' do
      get :new, params: { filter: { format: 'html' } }

      expect(response).to have_http_status(:ok)
      # On a new (blank) record, the filter value should be pre-selected
      expect(response.body).to have_selector(
        'select#admin_config_library_format option[selected]', text: 'html'
      )
    end
  end
end
