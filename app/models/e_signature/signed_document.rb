module ESignature
  class SignedDocument

    # @return [User] the current user signed in to the app
    attr_reader :current_user
    # @return [User] the current user at the time the document was prepared for signature
    attr_reader :signing_user

    # Setup  and run the document ready for signature, based on the activity configuration
    # @param activity_log [String] the activity log item in which a user will be performing the e-signature
    # @return [ESignature::SignedDocument]
    def self.prepare_activity_for_signature activity_log, current_user
      sd = self.new activity_log, current_user
      res = sd.prepare
      return unless res
      sd
    end

    # Sign the prepared document
    def sign! current_user, password
      @current_user = current_user
      raise FphsException.new "The current user does not match the user that prepared the document for signature" unless current_user == @signing_user

      validate_prepared_doc_digest
    end


    def initialize activity_log, current_user
      @activity_log = activity_log
      @current_user = current_user
      @signing_user = current_user
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

    def prepared_doc_digest
      get_document_tag(:signprepdoc)
    end

    def validate_prepared_doc
      validate_prepared_doc_digest
    end

    private

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
    end
end
