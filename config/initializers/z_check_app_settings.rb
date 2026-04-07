class Settings
  def self.configuration_failed_reason
    @configuration_failed_reason ||= []
  end

  #
  # Check the configurations
  def self.configuration_successful?
    if Settings::AllowUsersToRegister
      registration_admin_ok = Settings::RegistrationAdminEmail.present? && RegistrationHandler.registration_admin
      registration_template_ok = Settings::DefaultUserTemplateEmail.present? && RegistrationHandler.registration_template_user
      unless registration_admin_ok
        configuration_failed_reason << 'User self-registration admin email address is not set, or is not found as an administrator profile'
      end

      unless registration_template_ok
        configuration_failed_reason << 'User self-registration template email address is not set, or is not found as an user profile'
      end
    end

    unless User.template_user
      configuration_failed_reason << "Template user email #{Settings::TemplateUserEmail.downcase} is not a user profile"
    end
    configuration_failed_reason << 'NotificationsFromEmail address is blank.' if NotificationsFromEmail.blank?
    configuration_failed_reason << 'AdminEmail address is blank.' if AdminEmail.blank?
    configuration_failed_reason << 'BatchUserEmail address is blank.' if BatchUserEmail.blank?
    configuration_failed_reason << 'BatchUserEmail does not match a user profile' unless User.batch_user
    configuration_failed_reason << 'EncryptionSecretKeyBase is not set' if EncryptionSecretKeyBase.blank?
    configuration_failed_reason << 'EncryptionSalt is not set' if EncryptionSalt.blank?

    configuration_failed_reason.uniq!
    configuration_failed_reason.blank?
  end
end
