# frozen_string_literal: true

# Purpose: Verify that a User with api_access_only: true and a corrupted
# (undecryptable) otp_secret can still be loaded and used without raising
# ActiveRecord::Encryption::Errors::Decryption. Background jobs and API
# authentication must not crash when encountering corrupt OTP secrets.
#
# Related issue: consected/restructure#1226

require 'rails_helper'

RSpec.describe User, 'api_access_only user with corrupted OTP secret' do
  include UserSupport

  before :each do
    create_admin
    @user, = create_user
    @user.current_admin = @admin
    @user.api_access_only = true
    @user.save!
    @user.reload
  end

  describe 'when otp_secret is corrupted' do
    before :each do
      User.connection.execute("UPDATE users SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@user.id}")
      @user.reload
    end

    it 'returns nil from otp_secret without raising' do
      expect(@user.otp_secret).to be_nil
    end

    it 'allows reading other attributes normally' do
      @user.otp_secret # trigger the read
      expect(@user.email).to be_present
      expect(@user.id).to be_present
      expect(@user.api_access_only).to be true
    end
  end
end
