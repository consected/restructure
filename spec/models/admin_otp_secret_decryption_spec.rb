# frozen_string_literal: true

# Purpose: Verify that an Admin with a corrupted (undecryptable) otp_secret column
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

RSpec.describe Admin, 'OTP secret decryption handling' do
  include UserSupport

  before :each do
    @admin, = create_admin
  end

  describe 'when otp_secret is corrupted' do
    before :each do
      Admin.connection.execute("UPDATE admins SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@admin.id}")
      @admin.reload
    end

    it 'returns nil from otp_secret without raising' do
      expect(@admin.otp_secret).to be_nil
    end

    it 'reports otp_secret_decryption_failed? as true' do
      @admin.otp_secret # trigger the read
      expect(@admin.otp_secret_decryption_failed?).to be true
    end

    it 'blocks authentication without a prior explicit otp_secret read' do
      # active_for_authentication? must prime the flag itself (no manual otp_secret call here)
      expect(@admin.active_for_authentication?).to be false
    end

    it 'returns false from active_for_authentication?' do
      @admin.otp_secret # trigger the read
      expect(@admin.active_for_authentication?).to be false
    end

    it 'returns :otp_secret_invalid from inactive_message' do
      @admin.otp_secret # trigger the read
      expect(@admin.inactive_message).to eq(:otp_secret_invalid)
    end
  end

  describe 'admin recovery via reset_two_factor_auth' do
    before :each do
      Admin.connection.execute("UPDATE admins SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@admin.id}")
      @admin.reload
      @admin.otp_secret # trigger the corruption detection
    end

    it 'clears corruption after reset and save' do
      expect(@admin.otp_secret_decryption_failed?).to be true

      @admin.reset_two_factor_auth
      @admin.save!
      @admin.reload

      expect(@admin.otp_secret).to be_present
      expect(@admin.otp_secret_decryption_failed?).to be false
      expect(@admin.active_for_authentication?).to be true
    end
  end
end
