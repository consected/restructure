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

      raise_if_no_key!

      new.encrypt_and_sign(value)
    end

    def self.decrypt(value)
      return unless value.present?

      raise_if_no_key!

      new.decrypt_and_verify(value)
    end

    def self.raise_if_no_key!
      unless Settings::EncryptionSecretKeyBase
        raise FphsException, 'Encryption needs Settings::EncryptionSecretKeyBase to be set'
      end
      raise FphsException, 'Encryption needs Settings::EncryptionSalt to be set' unless Settings::EncryptionSalt
      raise FphsException, 'Encryption KEY not set' unless defined?(KEY) && KEY
    end

    private

    def encryptor
      ActiveSupport::MessageEncryptor.use_authenticated_message_encryption = false
      ActiveSupport::MessageEncryptor.new(KEY)
    end
  end
end
