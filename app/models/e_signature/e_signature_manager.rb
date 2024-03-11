# frozen_string_literal: true

module ESignature
  #
  # Provide e-signature support to an activity log style model.
  # To simplify the inclusion of this functionality in activity logs of arbitrary implementations
  # use:
  #   ESignature::ESignatureManager.enable_e_signature_for klass
  #
  # which will only include the functionality if the appropriate e_signed_status
  # field is present in the implementation.
  module ESignatureManager
    extend ActiveSupport::Concern

    InProgressStatus = 'in progress'
    SignedStatus = 'signed'
    CancelledStatus = 'cancelled'
    SignNowStatus = 'sign now'
    CancelStatus = 'cancel and unlock'

    # The following fields must be in the activity log table
    ExpectedFields = ['e_signed_document', 'e_signed_how', 'e_signed_at', 'e_signed_by', 'e_signed_code'].freeze

    included do
      validate :e_signature_password_correct
      validate :prevent_change
      before_create :set_status
      before_save :set_new_status

      attr_reader :e_signed_authenticated
      attr_reader :signed_document
      attr_accessor :e_signature_password, :e_signature_otp_attempt
    end

    # Method called by classes wanting to include e-signature functionality based on the avaiability of appropriate fields
    # Any class may call this method. Only those with appropriate fields will have the functionality enabled
    # Call with `ESignature::ESignatureManager.enable_e_signature_for klass`
    def self.enable_e_signature_for(klass)
      klass.include ESignature::ESignatureManager if klass.attribute_names.include? 'e_signed_status'
    end

    class_methods do
      def has_e_signature?
        attribute_names.include? 'e_signed_status'
      end
    end

    # Setup the document ready for signature, based on the activity configuration
    # @param activity_log [String] the activity log item in which a user will be performing the e-signature
    # @return [ESignature::SignedDocument]
    def prepare_activity_for_signature
      validate_configuration
      create_or_find_ref_to_sign
      self.e_signed_document = @signed_document.prepare_for_signature
      @signed_document
    end

    # Sign the record
    def sign!(password = nil, otp_attempt = nil)
      password ||= e_signature_password
      otp_attempt ||= e_signature_otp_attempt
      @signed_document = SignedDocument.new self, find_reference_to_sign

      raise ESignatureException, 'Signed document not prepared for signature' unless @signed_document
      raise ESignatureUserError, "password #{@authentication_error}" unless check_password(password, otp_attempt)

      @prepared_doc = @signed_document.sign! current_user, password

      self.e_signed_document = @prepared_doc
      self.e_signed_at = @signed_document.signed_at_timestamp
      self.e_signed_how = 'password'
      self.e_signed_by = current_user
      self.e_signed_code = @signed_document.signature_digest
      self.e_signed_status = SignedStatus

      send_document_to_filestore
    end

    def e_signature_in_progress?
      e_signed_status == SignNowStatus
    end

    def set_status
      return unless e_signed_status.blank?
      return unless extra_log_type_config.e_sign

      self.e_signed_status = InProgressStatus
    end

    def e_signature_password_correct
      return true unless e_signature_in_progress?

      check_password(e_signature_password, e_signature_otp_attempt)
      errors.add :password, @authentication_error unless @e_signed_authenticated
    end

    def check_password(password, otp_attempt)
      return @e_signed_authenticated unless @e_signed_authenticated.nil?

      @e_signed_authenticated = false

      if User.two_factor_auth_disabled
        unless password.present?
          @authentication_error = 'is empty. Please try again.'
          return
        end
        @e_signed_authenticated = current_user.valid_password?(password)
      else
        unless password.present? && otp_attempt.present?
          @authentication_error = 'or two-factor authentication code is empty. Please try again.'
          return
        end
        @e_signed_authenticated = current_user.valid_password?(password) && current_user.validate_one_time_code(otp_attempt)
      end

      if @e_signed_authenticated
        current_user.failed_attempts = 0
        current_user.save!
      else

        current_user.increment_failed_attempts
        current_user.save!

        current_user.lock_access! if current_user.send :attempts_exceeded?

        errstr_prefix = 'or two-factor authentication code ' unless User.two_factor_auth_disabled

        if current_user.access_locked?
          @authentication_error = "#{errstr_prefix}is not correct. Account has been locked."
          current_user.locked_at = Time.now
        elsif current_user.send :last_attempt?
          @authentication_error = "#{errstr_prefix}is not correct. One more attempt before account is locked."
        else
          @authentication_error = "#{errstr_prefix}is not correct. Please try again."
        end

      end
      @e_signed_authenticated
    end

    def prevent_change
      if e_signed_status_was.in?([CancelledStatus, SignedStatus]) && (
           e_signed_status_changed? || e_signed_document_changed? || e_signed_how_changed? ||
           e_signed_at_changed? || e_signed_by_changed? || e_signed_code_changed?
         )
        raise ESignatureUserError, "Record has already been #{e_signed_status_was}"
      end
    end

    private

    # Check that the activity log configuration has appropriate fields and is ready for use
    def validate_configuration
      res = (ExpectedFields - attribute_names).empty?
      raise ESignatureException, "Missing the expected fields for e-signature (#{ExpectedFields.join(', ')})" unless res
    end

    # Create the document to sign or find an existing document to sign
    # Only create a new document to sign if {e_sign: create_document:} is set.
    # This create_document: configuration is left open for extension, so anything
    # truthy will satisfy the condition.
    def create_or_find_ref_to_sign
      if extra_log_type_config.e_sign[:create_document]
        mn = extra_log_type_config.e_sign.dig(:document_reference, :item).first.first
        signdoc_class = ModelReference.to_record_class_for_type(mn)
        to_sign = signdoc_class.new(master:, current_user:)
        to_sign.force_save!
        to_sign.ignore_configurable_valid_if = true
        to_sign.send(:force_write_user)
        to_sign.save!
        ModelReference.create_with(self, to_sign, force_create: false)
      end

      @signed_document = SignedDocument.new self, find_reference_to_sign
    end

    # Find the model reference and subsequently the record it points to,
    # using the activity configuration for `e_sign`
    def find_reference_to_sign
      ref = model_references(reference_type: :e_sign).first
      raise ESignatureException, 'Record referenced for signature can not be found' unless ref

      @e_sign_document = ref.to_record
    end

    # Set a new status where the current value represents an action
    def set_new_status
      if e_signed_status == CancelStatus
        self.e_signed_status = CancelledStatus
      elsif e_signed_status == SignNowStatus
        sign!
      end
    end

    def send_document_to_filestore
      cont = container
      raise ESignature::ESignatureException, 'No filestore container available to store the signed document' unless cont

      temp_file = Tempfile.new
      temp_file.write e_signed_document

      fn = "signed document by #{e_signed_by} at #{@signed_document.signed_at.iso8601}.html"

      begin
        NfsStore::Import.import_file cont.id, fn, temp_file.path, current_user
      ensure
        temp_file.close
        temp_file.unlink
      end
    end
  end
end
