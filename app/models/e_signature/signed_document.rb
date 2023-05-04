# frozen_string_literal: true

module ESignature
  class SignedDocument
    PendingSignatureCaption = '[Pending Signature]'

    # @return [User] the current user signed in to the app
    attr_reader :current_user
    # @return [String] the prepared document HTML
    attr_reader :prepared_doc
    # @return [String] printable timestamp for the signature action
    attr_reader :signed_at_timestamp
    # @return [String] salt generated at sign time
    attr_reader :document_salt
    # @return [String] signature digest generated for signature
    attr_reader :signature_digest
    # @return [Time] timestamp for the signature action
    attr_reader :signed_at

    # Sign the prepared document
    def sign!(current_user, _password)
      @current_user = current_user
      unless current_user == signing_user
        raise ESignatureUserError, 'The current user does not match the user that prepared the document for signature'
      end

      validate_prepared_doc_digest
      set_signature_timestamp
      salt_document
      sign_document

      validate_signature
      @prepared_doc
    end

    # Validate a text document, using only its self-contained data for reference
    def self.validate_text_document(test_doc)
      sd = new
      sd.validate_signature test_doc
    end

    # Validate the signature based on the current document
    # Check the salt, pepper and prepared document digest create a valid signature
    # @param test_doc [String | nil] optionally provide a document to test, otherwise use the @prepared_doc
    def validate_signature(test_doc = nil)
      test_doc ||= @prepared_doc

      doc_signature = get_document_tag :esigncode, from: test_doc
      doc_salt = get_document_tag :esignuniquecode, from: test_doc
      validate_prepared_doc_digest test_doc

      new_pdd = prepared_doc_digest(from: test_doc)
      new_signature = Hashing.sign_with(doc_salt, new_pdd)
      raise ESignatureUserError, 'Document signature is invalid' unless doc_signature == new_signature

      true
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
    def prepared_doc_digest(from: nil)
      get_document_tag(:esignprepdoc, from: from)
    end

    def signing_user
      res = get_document_tag(:esignuser) || ''

      id = res.match(/\(id: (\d+)\)/)
      return unless id[1]

      id = id[1].to_i
      User.find(id)
    end

    private

    # Initialization requires activity_log and e_sign_document to be set in normal signing operation
    # If just being used for validation of a text document, leave these empty
    # If the document has been prepared for signing, it will be pulled from the
    # activity record directly, and does not need to be prepared again.
    def initialize(activity_log = nil, e_sign_document = nil)
      return unless activity_log && e_sign_document

      @current_user = activity_log.current_user
      esc = activity_log.extra_log_type_config.e_sign
      @specified_fields = esc[:fields]
      @document_title = esc[:title]
      @document_intro = esc[:intro]
      @prepared_doc = activity_log.e_signed_document
      @e_sign_document = e_sign_document
    end

    # Prepare the HTML document ready for signature
    # It incorporates a prepared document digest (checksum) to allow verification that
    # the document has not changed between preparation and signature execution
    def prepare
      raise ESignatureException, 'No document to prepare for signature' unless @e_sign_document

      @prepared_doc = generate_doc_from_model
      save_prepared_doc_digest
    end

    # @param test_doc [String | nil] optionally provide the document to test, otherwise use the @prepared_doc
    # @raise [ESignatureException] if the current document content does not match the original prepared document, based on the checksum
    def validate_prepared_doc_digest(test_doc = nil)
      test_doc ||= @prepared_doc
      pdd = prepared_doc_digest from: test_doc

      temp_doc = test_doc.dup

      set_document_tag :esigncode, PendingSignatureCaption, from: temp_doc
      set_document_tag :esignuniquecode, PendingSignatureCaption, from: temp_doc
      set_document_tag :esigntimestamp, PendingSignatureCaption, from: temp_doc
      set_document_tag(:esignprepdoc, '', from: temp_doc)
      new_pdd = Hashing.checksum(temp_doc)
      raise ESignatureException, 'The document prepared for signature has changed' unless new_pdd == pdd

      true
    end

    # Generate digest to act as checksum for the prepared document and verify
    # at signature execution that it hasn't changed. Place it into a known document tag
    def save_prepared_doc_digest
      d = Hashing.checksum(@prepared_doc)
      set_document_tag(:esignprepdoc, d)
    end

    # Generate the HTML document from the model to be signed and additional configuration
    # in the activity configuration for `e_sign`
    def generate_doc_from_model
      # Get the config for the model to be signed
      elt = @e_sign_document.option_type_config

      # Use either the specified fields in the activity log e_sign configuration,
      # or the fields specified in the model to be signed
      sign_fields = @specified_fields || elt.fields

      # Limit the attributes to just the specified fields, and order them according the field config
      att_order = @e_sign_document.class.permitted_params
      all_atts = {}
      if att_order
        att_order.each do |a|
          a = a.to_s
          all_atts[a] = @e_sign_document.attributes[a]
        end
      else
        all_atts = @e_sign_document.attributes.dup
      end
      atts = all_atts.select { |k, _v| sign_fields.include? k }

      ApplicationController.render(template: 'e_signature/document', layout: 'e_signature', locals: {
                                     e_sign_document: @e_sign_document,
                                     prepared_document: self,
                                     attributes: atts,
                                     caption_before: elt.caption_before,
                                     labels: elt.caption_before,
                                     show_if: elt.show_if,
                                     current_user: current_user,
                                     document_title: @document_title,
                                     document_intro: @document_intro
                                   }).html_safe
    end

    # Set an esign tag in the document
    # @param tagname [Symbol|String] name of the HTML tag content to update
    # @param value [String] value to enter into the tag
    # @param from [String | nil] optional - ensure that either from is a mutable string, or
    #    if nil, @prepared_doc is a mutable string
    def set_document_tag(tagname, value, from: nil)
      from ||= @prepared_doc
      from.sub!(%r{<#{tagname}>.*</#{tagname}>}, "<#{tagname}>#{value}<\/#{tagname}>")
    end

    # Get the value from an esign tag in the document
    # @param tagname [Symbol|String] name of the HTML tag to get content from
    # @return [String] content from the tag
    def get_document_tag(tagname, from: nil)
      from ||= @prepared_doc
      from.match(%r{<#{tagname}>(.*)</#{tagname}>})[1]
    end

    # Adds the signature timestamp to the document and activity record
    def set_signature_timestamp
      time = Time.now
      @signed_at = time
      @signed_at_timestamp = TimeFormatting.printable_time time
      @signed_at_timestamp_ms = TimeFormatting.ms_timestamp(time)
      set_document_tag :esigntimestamp, @signed_at_timestamp
    end

    def generate_salt
      items = []
      items << @e_sign_document.class.table_name
      items << @e_sign_document.id
      items << current_user.id
      items << @signed_at_timestamp_ms
      items << SecureRandom.hex(10)

      items.compact!
      raise ESignatureException, 'Failed to generate valid salt' unless items.length == 5

      items.join('--')
    end

    # Generate salt for document to be signed: record type being signed, record id, user.id, ms timestamp and secure random hex string
    def salt_document
      raise ESignatureException, 'Document salt requires timestamp ms to be set' unless @signed_at_timestamp_ms

      @document_salt = generate_salt
      set_document_tag :esignuniquecode, @document_salt
      @document_salt
    end

    def sign_document
      raise ESignatureException, 'Document signature requires salt to be set' unless @document_salt

      @signature_digest = Hashing.sign_with @document_salt, prepared_doc_digest
      set_document_tag :esigncode, @signature_digest
      @signature_digest
    end
  end
end
