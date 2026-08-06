# frozen_string_literal: true

# Purpose: Regression coverage for the one-off otp_secret re-encryption data migration
# (issue #1293, db/migrate/20260804160000_reencrypt_otp_secrets_sha256.rb). Confirms the
# migration rewrites legacy SHA1-encrypted otp_secret ciphertext under the current SHA256 key
# without changing the decrypted OTP value, leaves already-SHA256 and blank values untouched,
# and skips (without raising) records whose otp_secret is corrupt.

require 'rails_helper'
require Rails.root.join('db/migrate/20260804160000_reencrypt_otp_secrets_sha256').to_s

RSpec.describe ReencryptOtpSecretsSha256 do
  include UserSupport

  def legacy_sha1_key_provider
    key_generator = ActiveRecord::Encryption::KeyGenerator.new(hash_digest_class: OpenSSL::Digest::SHA1)
    ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
      ActiveRecord::Encryption.config.primary_key,
      key_generator: key_generator
    )
  end

  # True only while a context restricted to the legacy SHA1 key can still decrypt the
  # record's current otp_secret ciphertext - i.e. it has not yet been re-encrypted with SHA256.
  def sha1_encrypted?(record)
    ActiveRecord::Encryption.with_encryption_context(key_provider: legacy_sha1_key_provider) do
      record.reload
      record.otp_secret
      !record.otp_secret_decryption_failed?
    end
  end

  before :each do
    create_admin
    @legacy_user, = create_user
    @current_user, = create_user

    legacy_secret = 'JBSWY3DPEHPK3PXP'
    ActiveRecord::Encryption.with_encryption_context(key_provider: legacy_sha1_key_provider) do
      @legacy_user.otp_secret = legacy_secret
      @legacy_user.save!(validate: false)
      # Admin model coverage: the migration processes both User and Admin.
      @admin.otp_secret = legacy_secret
      @admin.save!(validate: false)
    end

    @current_user.otp_secret = 'KRSXG5CTMVRXEZLU'
    @current_user.save!(validate: false)

    @corrupt_user, = create_user
    User.connection.execute("UPDATE users SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@corrupt_user.id}")

    @blank_user, = create_user
    @blank_user.update_column(:otp_secret, nil)
  end

  it 'confirms the legacy user really is SHA1-encrypted before the migration runs (sanity check)' do
    expect(sha1_encrypted?(@legacy_user)).to be true
  end

  it 're-encrypts a legacy SHA1 otp_secret under SHA256 without changing the decrypted value' do
    expect { described_class.new.up }.not_to raise_error

    @legacy_user.reload
    expect(@legacy_user.otp_secret).to eq('JBSWY3DPEHPK3PXP')
    expect(sha1_encrypted?(@legacy_user)).to be false
  end

  it 're-encrypts a legacy SHA1 otp_secret on Admin the same way as on User' do
    described_class.new.up

    @admin.reload
    expect(@admin.otp_secret).to eq('JBSWY3DPEHPK3PXP')
    expect(sha1_encrypted?(@admin)).to be false
  end

  it 'leaves a blank otp_secret untouched' do
    expect { described_class.new.up }.not_to raise_error

    expect(@blank_user.reload.otp_secret).to be_nil
  end

  it 'leaves an already-SHA256-encrypted otp_secret value unchanged' do
    described_class.new.up

    @current_user.reload
    expect(@current_user.otp_secret).to eq('KRSXG5CTMVRXEZLU')
  end

  it 'skips a corrupt otp_secret without raising' do
    expect { described_class.new.up }.not_to raise_error

    @corrupt_user.reload
    expect(@corrupt_user.otp_secret).to be_nil
    expect(@corrupt_user.otp_secret_decryption_failed?).to be true
  end

  it 'does not run model validations or callbacks (update_column bypass)' do
    # A full `save`/`update` would touch `updated_at`; `update_column` deliberately does not.
    # An unrelated invalid `failed_attempts` value surviving the run also confirms no
    # validation/callback chain ran.
    original_updated_at = @legacy_user.reload.updated_at
    @legacy_user.update_column(:failed_attempts, 999)

    expect { described_class.new.up }.not_to raise_error

    @legacy_user.reload
    expect(@legacy_user.updated_at).to eq original_updated_at
    expect(@legacy_user.failed_attempts).to eq 999
  end
end
