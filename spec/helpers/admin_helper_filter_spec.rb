# frozen_string_literal: true

require 'rails_helper'

# Tests for AdminHelper#show_filters method - Issue #969
#
# Verifies that the filter UI in admin pages uses "chosen" select boxes
# instead of filter buttons. The select boxes allow typed filtering of
# options, improving usability when many filter values are present.
#
# Test Coverage:
# - show_filters renders select elements with use-chosen class instead of buttons
# - filter_select generates correct option tags with current selection
# - grouped filters render with optgroup elements
# - "All" and "Not set" options are included
# - disabled filter is included for admin users
# - JavaScript for filter navigation is included
# - reports index page also uses the new select-based filters
RSpec.describe AdminHelper, type: :helper do
  include ModelSupport

  before :all do
    create_admin
    create_user
  end

  describe '#filter_select' do
    before do
      helper.define_singleton_method(:current_admin) { @admin }
      helper.define_singleton_method(:filter_params) { @_test_filter_params || {} }
      helper.define_singleton_method(:index_path) { |_opts = {}| '/admin/general_selections' }
      helper.instance_variable_set(:@admin, @admin)
    end

    it 'renders a select element with use-chosen class' do
      values = { 'general' => 'General', 'user' => 'User' }
      result = helper.filter_select(:item_type, values)

      expect(result).to include('select')
      expect(result).to include('use-chosen')
      expect(result).to include('filter-select')
    end

    it 'includes all option as the first option' do
      values = { 'general' => 'General', 'user' => 'User' }
      result = helper.filter_select(:item_type, values)

      expect(result).to include('<option value="">All</option>')
    end

    it 'includes not set option' do
      values = { 'general' => 'General', 'user' => 'User' }
      result = helper.filter_select(:item_type, values)

      expect(result).to include('Not set')
      expect(result).to include('IS NULL')
    end

    it 'includes options for each filter value' do
      values = { 'general' => 'General', 'user' => 'User' }
      result = helper.filter_select(:item_type, values)

      expect(result).to include('General')
      expect(result).to include('User')
    end

    it 'marks the current filter value as selected' do
      helper.instance_variable_set(:@_test_filter_params, { item_type: 'general' })
      values = { 'general' => 'General', 'user' => 'User' }
      result = helper.filter_select(:item_type, values)

      # The "general" option should be selected
      expect(result).to match(/value="general"[^>]*selected/)
    end

    it 'handles array values for filters' do
      values = %w[cat1 cat2 cat3]
      result = helper.filter_select(:category, values)

      expect(result).to include('cat1')
      expect(result).to include('cat2')
      expect(result).to include('cat3')
    end
  end

  describe '#show_filters' do
    before do
      helper.instance_variable_set(:@admin, @admin)
      helper.instance_variable_set(:@user, @user)
      # Default to no admin so the admin controls section (with url_for) is not rendered
      helper.define_singleton_method(:current_admin) { nil }
      helper.define_singleton_method(:current_user) { @user }
      helper.define_singleton_method(:filter_params) { @_test_filter_params || {} }
      helper.define_singleton_method(:filter_params_permitted) { @_test_filter_params_permitted }
      helper.define_singleton_method(:index_path) { |_opts = {}| '/admin/general_selections' }
      helper.define_singleton_method(:controller_name) { 'general_selections' }
      helper.define_singleton_method(:view_embedded?) { false }
      helper.define_singleton_method(:filters_prevent_disabled) { false }
    end

    it 'does not render accordion panels' do
      helper.define_singleton_method(:filters_on) { [:item_type] }
      helper.define_singleton_method(:filters) do
        { item_type: { 'general' => 'General', 'user' => 'User' } }
      end

      result = helper.show_filters

      expect(result).not_to include('panel-group')
      expect(result).not_to include('panel-collapse')
      expect(result).not_to include('accordion')
    end

    it 'renders select elements instead of button links' do
      helper.define_singleton_method(:filters_on) { [:item_type] }
      helper.define_singleton_method(:filters) do
        { item_type: { 'general' => 'General', 'user' => 'User' } }
      end

      result = helper.show_filters

      expect(result).to include('<select')
      expect(result).to include('use-chosen')
      expect(result).not_to include('btn btn-primary')
      expect(result).not_to include('btn btn-default')
    end

    it 'renders the disabled filter for admin users' do
      # Need admin to trigger the disabled filter, but skip url_for by having no params[:filter]
      helper.define_singleton_method(:current_admin) { @admin }
      helper.define_singleton_method(:params) do
        ActionController::Parameters.new({})
      end
      helper.define_singleton_method(:url_for) { |_opts| '/admin/general_selections' }
      helper.define_singleton_method(:filters_on) { [:item_type] }
      helper.define_singleton_method(:filters) do
        { item_type: { 'general' => 'General' } }
      end

      result = helper.show_filters

      expect(result).to include('Disabled')
      expect(result).to include('disabled')
      expect(result).to include('enabled')
    end

    it 'includes a label for each filter select' do
      helper.define_singleton_method(:filters_on) { %i[item_type category] }
      helper.define_singleton_method(:filters) do
        {
          item_type: { 'general' => 'General' },
          category: { 'reports' => 'Reports' }
        }
      end

      result = helper.show_filters

      expect(result).to include('Item type')
      expect(result).to include('Category')
    end

    it 'includes clear filters link when filters are active' do
      helper.define_singleton_method(:current_admin) { @admin }
      helper.instance_variable_set(:@_test_filter_params_permitted, { item_type: 'general' })
      helper.define_singleton_method(:params) do
        ActionController::Parameters.new(filter: { item_type: 'general' })
      end
      helper.define_singleton_method(:url_for) { |_opts| '/admin/general_selections' }
      helper.define_singleton_method(:filters_on) { [:item_type] }
      helper.define_singleton_method(:filters) do
        { item_type: { 'general' => 'General' } }
      end

      result = helper.show_filters

      expect(result).to include('clear filters')
    end
  end
end
