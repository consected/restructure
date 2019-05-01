module ESignature
  module ESignatureManager

    extend ActiveSupport::Concern

    InProgressStatus = 'in progress'.freeze
    SignedStatus = 'signed'.freeze
    CancelledStatus = 'cancelled'.freeze
    SignNowStatus = 'sign now'.freeze
    CancelStatus = 'cancel and unlock'.freeze

    # The following fields must be in the activity log table
    ExpectedFields = ["e_signed_document", "e_signed_how", "e_signed_at", "e_signed_by", "e_signed_code"].freeze

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
    def self.enable_e_signature_for klass
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
      @signed_document = SignedDocument.new self, find_reference_to_sign
      self.e_signed_document = @signed_document.prepare_for_signature
      return @signed_document
    end

    # Sign the record
    def sign! password=nil, otp_attempt=nil

      password ||= self.e_signature_password
      otp_attempt ||= self.e_signature_otp_attempt
      @signed_document = SignedDocument.new self, find_reference_to_sign

      raise ESignatureException.new("Signed document not prepared for signature") unless @signed_document
      raise ESignatureUserError.new("password #{@authentication_error}") unless check_password(password, otp_attempt)
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
      self.e_signed_status == SignNowStatus
    end

    def set_status
      return unless self.e_signed_status.blank?
      return unless self.extra_log_type_config.e_sign

      self.e_signed_status = InProgressStatus
    end

    def e_signature_password_correct
      return true unless e_signature_in_progress?
      check_password(self.e_signature_password, self.e_signature_otp_attempt)
      unless @e_signed_authenticated
        errors.add :password, @authentication_error
      end
    end

    def check_password password, otp_attempt

      return @e_signed_authenticated unless @e_signed_authenticated.nil?

      @e_signed_authenticated = false

      unless password.present? && otp_attempt.present?
        @authentication_error = 'or two-factor authentication code is empty. Please try again.'
        return
      end

      @e_signed_authenticated = current_user.valid_password?(password) && current_user.validate_one_time_code(otp_attempt)

      if @e_signed_authenticated
        current_user.failed_attempts = 0
        current_user.save!
      else

        current_user.increment_failed_attempts
        current_user.save!

        current_user.lock_access! if current_user.send :attempts_exceeded?

        if current_user.access_locked?
          @authentication_error = 'or two-factor authentication code is not correct. Account has been locked.'
          current_user.locked_at = Time.now
        elsif current_user.send :last_attempt?
          @authentication_error = 'or two-factor authentication code is not correct. One more attempt before account is locked.'
        else
          @authentication_error = 'or two-factor authentication code is not correct. Please try again.'
        end

      end
      @e_signed_authenticated
    end

    def prevent_change
      if e_signed_status.in?([CancelledStatus, SignedStatus]) && !e_signed_status_changed?
        raise ESignatureUserError.new "Record has already been #{e_signed_status}"
      end
    end


    private

      # Check that the activity log configuration has appropriate fields and is ready for use
      def validate_configuration
        res = (ExpectedFields - attribute_names).empty?
        raise ESignatureException.new "Missing the expected fields for e-signature (#{ExpectedFields.join(", ")})" unless res
      end


      # Find the model reference and subsequently the record it points to,
      # using the activity configuration for `e_sign`
      def find_reference_to_sign
        ref = self.model_references(reference_type: :e_sign).first
        raise ESignatureException.new "Record referenced for signature can not be found" unless ref
        @e_sign_document = ref.to_record
      end

      # Set a new status where the current value represents an action
      def set_new_status
        if self.e_signed_status == CancelStatus
          self.e_signed_status = CancelledStatus
        elsif self.e_signed_status == SignNowStatus
          self.sign!
        end
      end

      def send_document_to_filestore

        cont = container
        raise ESignature::ESignatureException.new "No filestore container available to store the signed document" unless cont

        temp_file = Tempfile.new
        temp_file.write self.e_signed_document

        fn = "signed document by #{self.e_signed_by} at #{@signed_document.signed_at.iso8601}.html"

        begin
          NfsStore::Import.import_file cont.id, fn, temp_file.path, self.current_user
        ensure
          temp_file.close
          temp_file.unlink
        end

      end

  end
end
