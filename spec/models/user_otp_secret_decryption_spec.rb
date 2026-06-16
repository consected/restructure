# frozen_string_literal: true

# Purpose: Verify that a User with a corrupted (undecryptable) otp_secret column
# does not raise ActiveRecord::Encryption::Errors::Decryption. Instead, the
# SafeOtp concern should:
#   - return nil from otp_secret
#   - flag otp_secret_decryption_failed? as true
#   - block login via active_for_authentication? returning false
#   - report :otp_secret_invalid as the inactive_message
#   - allow admin recovery via reset_two_factor_auth
#
# Related issue: consected/restructure#1226

require 'rails_helper'

RSpec.describe User, 'OTP secret decryption handling' do
  include UserSupport

  before :each do
    create_admin
    @user, = create_user
  end

  describe 'when otp_secret is corrupted' do
    before :each do
      # Bypass ActiveRecord encryption to write raw garbage to the column
      User.connection.execute("UPDATE users SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@user.id}")
      @user.reload
    end

    it 'returns nil from otp_secret without raising' do
      expect(@user.otp_secret).to be_nil
    end

    it 'reports otp_secret_decryption_failed? as true' do
      @user.otp_secret # trigger the read
      expect(@user.otp_secret_decryption_failed?).to be true
    end

    it 'blocks authentication without a prior explicit otp_secret read' do
      # active_for_authentication? must prime the flag itself (no manual otp_secret call here)
      expect(@user.active_for_authentication?).to be false
    end

    it 'returns false from active_for_authentication?' do
      @user.otp_secret # trigger the read
      expect(@user.active_for_authentication?).to be false
    end

    it 'returns :otp_secret_invalid from inactive_message' do
      @user.otp_secret # trigger the read
      expect(@user.inactive_message).to eq(:otp_secret_invalid)
    end
  end

  describe 'non-otp_secret attribute decryption errors are not swallowed' do
    before :each do
      User.connection.execute("UPDATE users SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@user.id}")
      @user.reload
    end

    it 'raises decryption errors for non-otp_secret attributes via attributes' do
      # Simulate a Decryption failure on a non-otp attribute at the _read_attribute level;
      # the attributes override must re-raise it (not silence it like it does for otp_secret).
      original_read = @user.method(:_read_attribute)
      allow(@user).to receive(:_read_attribute) do |attr_name, &block|
        raise ActiveRecord::Encryption::Errors::Decryption if attr_name.to_s == 'email'

        original_read.call(attr_name, &block)
      end
      expect { @user.attributes }.to raise_error(ActiveRecord::Encryption::Errors::Decryption)
    end
  end

  describe 'admin recovery via reset_two_factor_auth' do
    before :each do
      User.connection.execute("UPDATE users SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@user.id}")
      @user.reload
      @user.otp_secret # trigger the corruption detection
    end

    it 'clears corruption after reset and save' do
      expect(@user.otp_secret_decryption_failed?).to be true

      @user.reset_two_factor_auth
      @user.save!
      @user.reload

      expect(@user.otp_secret).to be_present
      expect(@user.otp_secret_decryption_failed?).to be false
      expect(@user.active_for_authentication?).to be true
    end
  end
end
