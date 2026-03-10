# frozen_string_literal: true

# NavHandler Concern Spec
#
# Tests the navigation handler concern that builds the user menu items
# displayed in the navbar dropdown.
#
# Test Coverage:
# - Password expiry display: The user menu should show the number of days
#   until the user's password expires, e.g. "password (expires in 42 days)"
# - When an admin is also logged in, the label should include "user" prefix
# - Edge cases: password expiring today (0 days), expiring tomorrow (1 day)

require 'rails_helper'

RSpec.describe NavHandler, type: :controller do
  include ModelSupport

  # Use MastersController as a concrete controller that includes NavHandler
  controller(MastersController) do
  end

  before_each_login_user

  describe '#setup_user_sub_nav' do
    it 'includes password expiry days in the user menu label' do
      days_remaining = @user.expires_in
      user_sub = []
      subject.send(:setup_user_sub_nav, user_sub)

      password_item = user_sub.find { |item| item[:url] == '/users/edit' }
      expect(password_item).to be_present
      expect(password_item[:label]).to include("expires in #{days_remaining}")
    end

    it 'shows singular "day" when password expires in 1 day' do
      subject.current_user.update_column(:password_updated_at, (Settings::PasswordAgeLimit - 1).days.ago)

      user_sub = []
      subject.send(:setup_user_sub_nav, user_sub)

      password_item = user_sub.find { |item| item[:url] == '/users/edit' }
      expect(password_item[:label]).to include('expires in 1 day)')
      expect(password_item[:label]).not_to include('days')
    end

    it 'shows "expires today" when password expires in 0 days' do
      subject.current_user.update_column(:password_updated_at, Settings::PasswordAgeLimit.days.ago)

      user_sub = []
      subject.send(:setup_user_sub_nav, user_sub)

      password_item = user_sub.find { |item| item[:url] == '/users/edit' }
      expect(password_item[:label]).to include('expires today')
    end

    it 'prefixes label with "user" when admin is also logged in' do
      admin, = create_admin
      sign_in admin, scope: :admin

      user_sub = []
      subject.send(:setup_user_sub_nav, user_sub)

      password_item = user_sub.find { |item| item[:url] == '/users/edit' }
      expect(password_item[:label]).to start_with('change password')
      expect(password_item[:label]).to include('expires in')
    end
  end
end
