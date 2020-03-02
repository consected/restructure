# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'electronic signature of records', type: 'model' do
  include ModelSupport
  include ESignatureSupport
  include ESignImportConfig

  ESignImportConfig.import_config

  before :all do
    setup_config

    @user_0, @good_password_0 = create_user
    @user, @good_password = create_user

    if @good_password.blank?
      raise 'Password can not be blank for successful tests'
    end
    raise 'Password must be valid' unless @user.valid_password?(@good_password)

    create_master

    setup_access_as :user

    setup_access_as :user, for_user: @user_0

    add_user_to_role 'nfs_store group 600'
    add_user_to_role 'nfs_store group 600', for_user: @user_0
  end

  describe 'generate a text field containing data to be signed' do
    before :each do
      @al = create_item
      @al.prepare_activity_for_signature
      @al.save!
    end

    it 'generates a reference document for signature' do
      expect(@al.e_signed_document).to start_with('<!doctype html>')
    end

    it 'removes the fields that are hidden based on conditional rules'

    it 'adds the user email address to the end of the document' do
      expect(@al.e_signed_document).to include("<small>Signed by</small> <esignuser>#{@user.first_name} #{@user.last_name} - #{@user.email} (id: #{@user.id})</esignuser>")
    end
  end

  describe 'validations performed to check integrity of the document and signer' do
    before :all do
      if @good_password.blank?
        raise 'Password can not be blank for successful tests'
      end
      unless @user.valid_password?(@good_password)
        raise 'Password must be valid'
      end
    end

    before :each do
      @al = create_item
      @al.current_user = @user
      @signed_document = @al.prepare_activity_for_signature
    end

    it 'validates that the prepared document has a digest' do
      expect(@signed_document.prepared_doc_digest).not_to be_blank
    end

    it 'signs the document with a good password and two-factor authentication code' do
      expect(@user.valid_password?(@good_password)).to be true
      expect do
        @al.e_signed_status = ESignature::ESignatureManager::SignNowStatus
        @al.e_signature_password = @good_password
        @al.e_signature_otp_attempt = @user.current_otp
        @al.save!
      end.not_to raise_error(ESignature::ESignatureUserError)
    end

    it 'validates the user that prepared the document is the same one that signs it' do
      @al2 = create_item
      @al2.prepare_activity_for_signature
      @al2.save!
      @al2 = @al2.class.find(@al2.id)
      @al2.current_user = @user_0
      expect do
        @al2.e_signed_status = ESignature::ESignatureManager::SignNowStatus
        @al2.e_signature_password = @good_password_0
        @al2.e_signature_otp_attempt = @user_0.current_otp
        @al2.save!
      end.to raise_error(ESignature::ESignatureUserError)
    end

    it 'prevents a signature with a bad password' do
      @al2 = create_item
      @al2.current_user = @user_0
      @al2.prepare_activity_for_signature
      expect do
        @al2.e_signature_password = @good_password + '!'
        @al2.e_signature_otp_attempt = @user.current_otp
        @al2.e_signed_status = ESignature::ESignatureManager::SignNowStatus
        @al2.save!
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Password or two-factor authentication code is not correct. Please try again.')
    end

    it 'prevents a signature with a bad two-factor authentication code' do
      @al2 = create_item
      @al2.current_user = @user_0
      @al2.prepare_activity_for_signature
      expect do
        @al2.e_signature_password = @good_password
        @al2.e_signature_otp_attempt = '000000'
        @al2.e_signed_status = ESignature::ESignatureManager::SignNowStatus
        @al2.save!
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Password or two-factor authentication code is not correct. Please try again.')
    end
  end

  describe 'at time of applying the signature' do
    before :each do
      # Recreate a new user for each test, since two-factor authentication codes can' be reused
      @user, @good_password = create_user
      setup_access_as :user
      add_user_to_role 'nfs_store group 600'
      @master.current_user = @user

      if @good_password.blank?
        raise 'Password can not be blank for successful tests'
      end

      @al = create_item
      @signed_document = @al.prepare_activity_for_signature
      @al.save!
    end

    it 'raises an error if the prepared document has changed' do
      @al2 = create_item
      @al2.current_user = @user
      @signed_document2 = @al2.prepare_activity_for_signature
      @al2.save!

      @al2.e_signed_document += '!'

      expect do
        @al2.e_signed_status = ESignature::ESignatureManager::SignNowStatus
        @al2.e_signature_password = @good_password
        @al2.e_signature_otp_attempt = @user.current_otp

        @al2.save!
      end.to raise_error(ESignature::ESignatureException)
    end

    it 'adds a date and time to end of the document' do
      @al.e_signed_status = ESignature::ESignatureManager::SignNowStatus
      @al.e_signature_password = @good_password
      @al.e_signature_otp_attempt = @user.current_otp

      @al.save!

      @al = @al.class.find(@al.id)

      res = @al.e_signed_document.match(%r{<small>Signed at</small> <esigntimestamp>(.+)</esigntimestamp>})[1]
      d = Time.parse(res)
      expect(d).to be_a Time
      expect(Time.now - d).to be < 100
    end

    it 'adds document unique code to the end to act as a salt ' do
      @al.e_signed_status = ESignature::ESignatureManager::SignNowStatus
      @al.e_signature_password = @good_password
      @al.e_signature_otp_attempt = @user.current_otp

      @al.save!

      res = @al.e_signed_document.match(%r{<small>Document unique code</small> <esignuniquecode>(.+)</esignuniquecode>})[1]
      expect(res.split('--').compact.length).to eq 5
      expect(res).to eq @al.signed_document.document_salt
    end

    it 'generates a hash digest using the prepared document checksum, the salt + a pepper, adds the hash to the document and its own field' do
      @al.e_signed_status = ESignature::ESignatureManager::SignNowStatus
      @al.e_signature_password = @good_password
      @al.e_signature_otp_attempt = @user.current_otp

      @al.save!

      res = @al.e_signed_document.match(%r{<small>Signature code</small> <esigncode>(.+)</esigncode>})[1]
      expect(res.length).to eq 64

      expect do
        @signed_document.validate_prepared_doc_digest
      end.not_to raise_error ESignature::ESignatureException
    end

    it 'saves the signed document back to the activity record' do
      @al.e_signed_status = ESignature::ESignatureManager::SignNowStatus
      @al.e_signature_password = @good_password
      @al.e_signature_otp_attempt = @user.current_otp

      @al.save!

      orig_sig = @al.signed_document.signature_digest
      @al = @al.class.find(@al.id)
      res = @al.e_signed_document.match(%r{<small>Signature code</small> <esigncode>(.+)</esigncode>})[1]
      expect(res).to eq orig_sig
    end

    it 'pushes the signed document to the filestore' do
      @al.e_signed_status = ESignature::ESignatureManager::SignNowStatus
      @al.e_signature_password = @good_password
      @al.e_signature_otp_attempt = @user.current_otp

      @al.save!

      expect(@al.container).to be_a NfsStore::Manage::Container
      sf = @al.container.stored_files.first
      expect(sf).to be_a NfsStore::Manage::StoredFile
      content = ''
      content = File.read sf.retrieval_path
      expect(content).to eq @al.e_signed_document
    end
  end

  describe 'after signing' do
    before :each do
      # Recreate a new user for each test, since two-factor authentication codes can' be reused
      @user, @good_password = create_user
      setup_access_as :user
      add_user_to_role 'nfs_store group 600'
      @master.current_user = @user

      @al = create_item
      @signed_document = @al.prepare_activity_for_signature

      @al.e_signed_status = ESignature::ESignatureManager::SignNowStatus
      @al.e_signature_password = @good_password
      @al.e_signature_otp_attempt = @user.current_otp

      @al.save!
    end

    it 'validates a text document purely against its self-contained data' do
      test_doc = @al.e_signed_document.dup

      ESignature::SignedDocument.validate_text_document test_doc

      # Mess up the signature digest
      test_doc.gsub! @al.e_signed_code, @al.e_signed_code.reverse

      expect do
        ESignature::SignedDocument.validate_text_document test_doc
      end.to raise_error ESignature::ESignatureUserError

      test_doc = @al.e_signed_document.dup
      ESignature::SignedDocument.validate_text_document test_doc

      test_doc.gsub! @al.current_user.email, 'another_email@test.com'
      expect do
        ESignature::SignedDocument.validate_text_document test_doc
      end.to raise_error ESignature::ESignatureException
    end

    it 'prevents the signed record being edited' do
      @al.e_signed_document = @al.e_signed_document + ' '
      expect do
        @al.save!
      end.to raise_error ESignature::ESignatureUserError
    end

    it 'prevents the signed record being signed again' do
      # check for signature digest field not null
      expect do
        @al.e_signed_status = ESignature::ESignatureManager::SignNowStatus
        @al.e_signature_password = @good_password
        @al.e_signature_otp_attempt = @user.current_otp

        @al.save!
      end.to raise_error FphsException
    end

    it 'sends a notification of the signature to the user with a signature summary and digest'
  end
end
