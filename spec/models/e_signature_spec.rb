require 'rails_helper'

RSpec.describe 'electronic signature of records', type: 'model' do

  include ModelSupport

  include ESignatureSupport
  include ESignImportConfig

  before :all do
    @user_0, _ = create_user
    create_user

    create_master

    import_config
    setup_access_as :user

    @al = create_item
  end

  describe "generate a text field containing data to be signed" do
    before :all do
      ::ESignature::SignedDocument.prepare_activity_for_signature(@al, @user)
    end

    it "generates a reference document for signature" do
      expect(@al.e_signed_document).to start_with('<!doctype html>')
    end

    it "removes the fields that are hidden based on conditional rules"

    it "adds the user email address to the end of the document" do
      expect(@al.e_signed_document).to include("<small>Signed by</small> <esignuser>#{@user.email} (id: #{@user.id})</esignuser>")
    end
  end

  describe "validations performed to check integrity of the document and signer" do
    before :all do
      @signed_document = ::ESignature::SignedDocument.prepare_activity_for_signature(@al, @user)
    end

    it "validates that the prepared document has a digest" do
      expect(@signed_document.prepared_doc_digest).not_to be_blank
    end

    it "validates the user that prepared the document is the same one that signs it" do
      expect {
        @signed_document.sign!(@user_0, @good_password)
      }.to raise_error(FphsException)
    end

    it "signs the document" do
      expect {
        @signed_document.sign!(@user, @good_password)
      }.not_to raise_error(FphsException)
    end

  end

  describe "at time of applying the signature" do
    before :each do
      @signed_document = ::ESignature::SignedDocument.prepare_activity_for_signature(@al, @user)
    end

    it "validates that the prepared document has not changed" do
      expect {
        @signed_document.sign!(@user, @good_password)
      }.not_to raise_error
    end

    it "raises an error if the prepared document has changed" do
      @signed_document.instance_variable_set(:@prepared_doc, @al.e_signed_document + ' ')
      expect {
        @signed_document.sign!(@user, @good_password)
      }.to raise_error
    end


    it "adds a date and time to end of the document" do

      @signed_document.sign!(@user, @good_password)
      res = @al.e_signed_document.match(/<small>Signed at<\/small> <esigntimestamp>(.+)<\/esigntimestamp>/)[1]
      d = Time.parse(res)
      expect(d).to be_a Time
      expect(Time.now - d).to be < 100

    end

    it "adds a date and time to end of the document and saves the timestamp for the salt" do
    end

    it "adds document unique code to the end to act as a salt " do
      @signed_document.sign!(@user, @good_password)
      # salt is user.id, record type being signed, record id and ms timestamp
      expect(@al.e_signed_document).to include("")
    end

    it "generates a hash digest using the whole document + a pepper, adds the hash to the document and its own field" do
      @signed_document.sign!(@user, @good_password)
      expect(@al.e_signed_document).to include("")
    end

    it "saves the signed document back to the activity record"

    it "pushes the signed document to the filestore"

  end

  describe "after signing" do

    it "prevents the signed record being edited" do
      # check for signature digest field not null

    end

    it "sends a notification of the signature to the user with a signature summary and digest" do
      # salt and digest
    end

    it "allows the signed document to be validated using its self-contained salt and digest" do
      # Remembers to remove the digest line from the document before regenerating it for comparison
    end



  end



end
