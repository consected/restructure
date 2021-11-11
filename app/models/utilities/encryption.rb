# frozen_string_literal: true

module Utilities
  # Simple symmetric encryption, based on https://pawelurbanek.com/rails-secure-encrypt-decrypt
  # Usage within a class:
  #
  # def api_token
  #   ::Utilities::Encryption.decrypt(encrypted_api_token)
  # end
  #
  # def api_token=(value)
  #   self.encrypted_api_token = ::Utilities::Encryption.encrypt(value)
  # end
  #
  class Encryption
    if Settings::EncryptionSecretKeyBase
      raise FphsException, 'Settings::EncryptionSalt not set' unless Settings::EncryptionSalt

      KEY = ActiveSupport::KeyGenerator.new(
        Settings::EncryptionSecretKeyBase
      ).generate_key(
        Settings::EncryptionSalt,
        ActiveSupport::MessageEncryptor.key_len
      ).freeze

      private_constant :KEY
    end

    delegate :encrypt_and_sign, :decrypt_and_verify, to: :encryptor

    def self.encrypt(value)
      return unless value.present?

      new.encrypt_and_sign(value)
    end

    def self.decrypt(value)
      return unless value.present?

      new.decrypt_and_verify(value)
    end

    private

    def encryptor
      ActiveSupport::MessageEncryptor.new(KEY)
    end
  end
end
