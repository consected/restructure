module ESignature
  class SignedDocument

    # The following fields must be in the activity log table
    ExpectedFields = ["e_signed_document", "e_signed_how", "e_signed_at", "e_signed_by", "e_signed_code"].freeze

    # @return [User] the current user signed in to the app
    attr_reader :current_user
    # @return [User] the current user at the time the document was prepared for signature
    attr_reader :signing_user

    # Setup  and run the document ready for signature, based on the activity configuration
    # @param activity_log [String] the activity log item in which a user will be performing the e-signature
    # @return [ESignature::SignedDocument]
    def self.prepare_activity_for_signature activity_log, current_user
      sd = self.new activity_log, current_user
      res = sd.prepare_activity_for_signature
      return unless res
      sd
    end

    # Sign the prepared document
    def sign! current_user, password
      @current_user = current_user
      raise FphsException.new "The current user does not match the user that prepared the document for signature" unless current_user == @signing_user

      validate_prepared_doc_digest
      set_signature_timestamp

      @activity_log.e_signed_document = @prepared_doc
    end

    # Validate the prepared document is in a good state for signature
    # Primarily it checks that the document has not changed since being prepared
    # so that the user is not unknowingly applying a signature to an altered document
    # Raises exceptions:
    # @raise (see #validate_prepared_doc_digest)
    # @return [True]
    def validate_prepared_doc
      validate_prepared_doc_digest
    end

    #
    # Internal methods
    #

    # Coordinate the preparation of an activity log record for signature
    def prepare_activity_for_signature
      validate_configuration
      prepare
    end

    # Get the stored prepared document digest checksum
    def prepared_doc_digest
      get_document_tag(:signprepdoc)
    end

    private

      def initialize activity_log, current_user
        @activity_log = activity_log
        @current_user = current_user
        @signing_user = current_user
      end


      # Check that the activity log configuration has appropriate fields and is ready for use
      def validate_configuration
        res = (ExpectedFields - @activity_log.attribute_names).empty?
        raise FphsException.new "Missing the expected fields for e-signature (#{ExpectedFields.join(", ")})" unless res
      end

      # Prepare the HTML document ready for signature
      # It incorporates a prepared document digest (checksum) to allow verification that
      # the document has not changed between preparation and signature execution
      def prepare
        find_reference_to_sign
        return unless @e_sign_document
        @prepared_doc = generate_doc_from_model
        save_prepared_doc_digest

        @activity_log.e_signed_document = @prepared_doc
      end

      # @raise [FphsException] if the current document content does not match the original prepared document, based on the checksum
      def validate_prepared_doc_digest
        pdd = prepared_doc_digest
        set_document_tag(:signprepdoc, '')
        new_pdd = Hashing.checksum(@prepared_doc)
        raise FphsException.new "The document prepared for signature has changed" unless new_pdd == pdd
        true
      end

      # Generate digest to act as checksum for the prepared document and verify
      # at signature execution that it hasn't changed. Place it into a known document tag
      def save_prepared_doc_digest
        d = Hashing.checksum(@prepared_doc)
        set_document_tag(:signprepdoc, d)
      end

      # Find the model reference and subsequently the record it points to,
      # using the activity configuration for `e_sign`
      def find_reference_to_sign
        ref = @activity_log.model_references(reference_type: :e_sign).first
        return unless ref
        @e_sign_document = ref.to_record
      end

      # Generate the HTML document from the model to be signed and additional configuration
      # in the activity configuration for `e_sign`
      def generate_doc_from_model

        # Get the config for the model to be signed
        elt = @e_sign_document.option_type_config

        # Use either the specified fields in the activity log e_sign configuration,
        # or the fields specified in the model to be signed
        specified_fields = @activity_log.extra_log_type_config.e_sign[:fields]
        sign_fields = specified_fields || elt.fields

        # Limit the attributes to just the specified fields
        atts = @e_sign_document.attributes.select {|k,v| sign_fields.include? k}

        ActionController::Base.new.render_to_string(template: 'e_signature/document', layout: 'e_signature', locals: {
          e_sign_document: @e_sign_document,
          prepared_document: self,
          attributes: atts,
          caption_before: elt.caption_before,
          labels: elt.caption_before,
          show_if: elt.show_if,
          current_user: self.current_user
        }).html_safe
      end

      # Set an esign tag in the document
      # @param tagname [Symbol|String] name of the HTML tag content to update
      # @param value [String] value to enter into the tag
      def set_document_tag tagname, value
        @prepared_doc.sub!(/<#{tagname}>.*<\/#{tagname}>/, "<#{tagname}>#{value}<\/#{tagname}>")
      end

      # Get the value from an esign tag in the document
      # @param tagname [Symbol|String] name of the HTML tag to get content from
      # @return [String] content from the tag
      def get_document_tag tagname
        @prepared_doc.match(/<#{tagname}>(.*)<\/#{tagname}>/)[1]
      end

      # Adds the signature timestamp to the document and activity record
      def set_signature_timestamp
        time = Time.now

        @signed_at_timestamp = TimeFormatting.printable_time time
        @signed_at_timestamp_ms = TimeFormatting.ms_timestamp(time)
        set_document_tag :esigntimestamp, @signed_at_timestamp

        @activity_log.e_signed_at = time
      end



    end
end
