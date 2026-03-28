# frozen_string_literal: true

# Expire Datetime Spec - Issue #330
#
# Tests for the optional expire_datetime field on User and Admin models.
#
# Test Coverage:
# - User model:
#   - expire_datetime field exists and can be set/read
#   - authentication blocked when expire_datetime is in the past
#   - authentication allowed when expire_datetime is nil (not set)
#   - authentication allowed when expire_datetime is in the future
#   - inactive_message returns :account_expired when expired
#   - account_expired? helper method returns correct boolean
#   - disabled takes precedence over expired for inactive_message
#
# - Admin model:
#   - expire_datetime field exists and can be set/read
#   - authentication blocked when expire_datetime is in the past
#   - authentication allowed when expire_datetime is nil (not set)
#   - authentication allowed when expire_datetime is in the future
#   - inactive_message returns :account_expired when expired
#   - account_expired? helper method returns correct boolean
#   - disabled takes precedence over expired for inactive_message

require 'rails_helper'

describe 'expire_datetime for User and Admin - Issue #330' do
  include ModelSupport
  include SetupHelper

  describe User do
    before(:each) do
      @user, @good_password = create_user
    end

    describe 'expire_datetime field' do
      it 'responds to expire_datetime' do
        expect(@user).to respond_to(:expire_datetime)
      end

      it 'can set and read expire_datetime' do
        future_time = 1.week.from_now
        @user.expire_datetime = future_time
        @user.current_admin = @admin
        @user.save!
        @user.reload
        expect(@user.expire_datetime).to be_within(1.second).of(future_time)
      end

      it 'defaults to nil when not set' do
        expect(@user.expire_datetime).to be_nil
      end
    end

    describe '#account_expired?' do
      it 'returns true when expire_datetime is in the past' do
        @user.expire_datetime = 1.hour.ago
        expect(@user.account_expired?).to be true
      end

      it 'returns false when expire_datetime is nil' do
        @user.expire_datetime = nil
        expect(@user.account_expired?).to be false
      end

      it 'returns false when expire_datetime is in the future' do
        @user.expire_datetime = 1.week.from_now
        expect(@user.account_expired?).to be false
      end
    end

    describe '#active_for_authentication?' do
      it 'returns false when expire_datetime is in the past' do
        @user.expire_datetime = 1.hour.ago
        expect(@user.active_for_authentication?).to be false
      end

      it 'returns true when expire_datetime is nil' do
        expect(@user.expire_datetime).to be_nil
        expect(@user.active_for_authentication?).to be true
      end

      it 'returns true when expire_datetime is in the future' do
        @user.expire_datetime = 1.week.from_now
        expect(@user.active_for_authentication?).to be true
      end

      it 'returns false when user is disabled regardless of expire_datetime' do
        create_admin
        @user.disabled = true
        @user.current_admin = @admin
        @user.expire_datetime = 1.week.from_now
        @user.save!
        expect(@user.active_for_authentication?).to be false
      end
    end

    describe '#inactive_message' do
      it 'returns :account_expired when expire_datetime is in the past' do
        @user.expire_datetime = 1.hour.ago
        expect(@user.inactive_message).to eq(:account_expired)
      end

      it 'returns :account_has_been_disabled when disabled, even if also expired' do
        create_admin
        @user.disabled = true
        @user.current_admin = @admin
        @user.expire_datetime = 1.hour.ago
        @user.save!
        expect(@user.inactive_message).to eq(:account_has_been_disabled)
      end
    end
  end

  describe Admin do
    before(:each) do
      ENV['FPHS_ADMIN_SETUP'] = 'yes'
      @admin, @good_password = create_admin 'test-admin-expire'
    end

    describe 'expire_datetime field' do
      it 'responds to expire_datetime' do
        expect(@admin).to respond_to(:expire_datetime)
      end

      it 'can set and read expire_datetime' do
        future_time = 1.week.from_now
        @admin.expire_datetime = future_time
        @admin.save!
        @admin.reload
        expect(@admin.expire_datetime).to be_within(1.second).of(future_time)
      end

      it 'defaults to nil when not set' do
        expect(@admin.expire_datetime).to be_nil
      end
    end

    describe '#account_expired?' do
      it 'returns true when expire_datetime is in the past' do
        @admin.expire_datetime = 1.hour.ago
        expect(@admin.account_expired?).to be true
      end

      it 'returns false when expire_datetime is nil' do
        @admin.expire_datetime = nil
        expect(@admin.account_expired?).to be false
      end

      it 'returns false when expire_datetime is in the future' do
        @admin.expire_datetime = 1.week.from_now
        expect(@admin.account_expired?).to be false
      end
    end

    describe '#active_for_authentication?' do
      it 'returns false when expire_datetime is in the past' do
        @admin.expire_datetime = 1.hour.ago
        expect(@admin.active_for_authentication?).to be false
      end

      it 'returns true when expire_datetime is nil' do
        expect(@admin.expire_datetime).to be_nil
        expect(@admin.active_for_authentication?).to be true
      end

      it 'returns true when expire_datetime is in the future' do
        @admin.expire_datetime = 1.week.from_now
        expect(@admin.active_for_authentication?).to be true
      end

      it 'returns false when admin is disabled regardless of expire_datetime' do
        @admin.current_admin = @admin
        @admin.expire_datetime = 1.week.from_now
        @admin.disable!
        expect(@admin.active_for_authentication?).to be false
      end
    end

    describe '#inactive_message' do
      it 'returns :account_expired when expire_datetime is in the past' do
        @admin.expire_datetime = 1.hour.ago
        expect(@admin.inactive_message).to eq(:account_expired)
      end

      it 'returns :account_has_been_disabled when disabled, even if also expired' do
        @admin.current_admin = @admin
        @admin.expire_datetime = 1.hour.ago
        @admin.disable!
        expect(@admin.inactive_message).to eq(:account_has_been_disabled)
      end
    end
  end
end
