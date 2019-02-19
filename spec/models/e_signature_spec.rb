require 'rails_helper'

RSpec.describe 'electronic signature of records', type: 'model' do

  include ModelSupport

  include ESignatureSupport
  include ESignImportConfig

  before :all do

    import_config
    @user_0, @good_password_0 = create_user
    @user, @good_password = create_user

    puts "@user #{@user.id} @good_password #{@good_password}"
    raise "Password can not be blank for successful tests" if @good_password.blank?
    raise "Password must be valid" unless @user.valid_password?(@good_password)

    create_master

    setup_access_as :user

    @al = create_item
  end

  describe "generate a text field containing data to be signed" do
    before :all do
      @al.prepare_activity_for_signature
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
      raise "Password can not be blank for successful tests" if @good_password.blank?
      raise "Password must be valid" unless @user.valid_password?(@good_password)
      @al.current_user = @user
      @signed_document = @al.prepare_activity_for_signature
    end

    before :each do
      @al.current_user = @user
    end

    it "validates that the prepared document has a digest" do
      expect(@signed_document.prepared_doc_digest).not_to be_blank
    end

    it "validates the user that prepared the document is the same one that signs it" do
      @al2 = create_item
      @al2.current_user = @user_0
      expect {
        @al2.sign!(@good_password_0)
      }.to raise_error(FphsException)
    end

    it "signs the document with a good password" do
      puts "@user #{@user.id} @good_password #{@good_password}"

      expect(@user.valid_password?(@good_password)).to be true

      expect {

        @al.sign!(@good_password)
      }.not_to raise_error(FphsException)
    end


    it "prevents a signature with a bad password" do
      @al.current_user = @user
      expect {
        @al.sign!(@good_password + '!')
      }.to raise_error(FphsException)
    end

  end

  describe "at time of applying the signature" do
    before :each do
      raise "Password can not be blank for successful tests" if @good_password.blank?
      @al = create_item
      @signed_document = @al.prepare_activity_for_signature

    end


    it "raises an error if the prepared document has changed" do
      @al2 = create_item
      @al2.current_user = @user
      @signed_document2 = @al2.prepare_activity_for_signature

      @signed_document2.instance_variable_set(:@prepared_doc, @al2.e_signed_document + ' ')
      expect {
        @al2.sign! @good_password
      }.to raise_error(FphsException)
    end


    it "adds a date and time to end of the document" do

      @al.sign! @good_password

      @al = @al.class.find(@al.id)

      res = @al.e_signed_document.match(/<small>Signed at<\/small> <esigntimestamp>(.+)<\/esigntimestamp>/)[1]
      d = Time.parse(res)
      expect(d).to be_a Time
      expect(Time.now - d).to be < 100

    end

    it "adds a date and time to end of the document and saves the timestamp for the salt" do
    end

    it "adds document unique code to the end to act as a salt " do
      @al.sign!(@good_password)
      # salt is user.id, record type being signed, record id and ms timestamp
      expect(@al.e_signed_document).to include("")
    end

    it "generates a hash digest using the whole document + a pepper, adds the hash to the document and its own field" do
      @al.sign!(@good_password)
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
