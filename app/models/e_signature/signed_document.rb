module ESignature
  class SignedDocument


    # @return [User] the current user signed in to the app
    attr_reader :current_user
    # @return [User] the current user at the time the document was prepared for signature
    attr_reader :signing_user
    # @return [String] the prepared document HTML
    attr_reader :prepared_doc
    # @return [Time] timestamp for the signature action
    attr_reader :signed_at_timestamp


    # Sign the prepared document
    def sign! current_user, password
      @current_user = current_user
      raise FphsException.new "The current user does not match the user that prepared the document for signature" unless current_user == @signing_user

      validate_prepared_doc_digest
      set_signature_timestamp

      @prepared_doc
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

    # Coordinate the preparation document for signature
    def prepare_for_signature
      prepare
    end

    # Get the stored prepared document digest checksum
    def prepared_doc_digest
      get_document_tag(:signprepdoc)
    end

    private

      def initialize activity_log, e_sign_document
        raise FphsException.new "Can not set up a signed document with nil activity_log" unless activity_log
        raise FphsException.new "Can not set up a signed document with nil e_sign_document" unless e_sign_document
        @activity_log = activity_log
        @current_user = activity_log.current_user
        @e_sign_document = e_sign_document
      end



      # Prepare the HTML document ready for signature
      # It incorporates a prepared document digest (checksum) to allow verification that
      # the document has not changed between preparation and signature execution
      def prepare
        return unless @e_sign_document
        @signing_user = @current_user
        @prepared_doc = generate_doc_from_model
        save_prepared_doc_digest
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


      end

  end
end
