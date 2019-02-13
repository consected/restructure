require 'rails_helper'

Rspec.describe 'electronic signature of records', type: 'model' do

  include ModelSupport

  include ActivityLogSupport

  before :all do
    create_user
    create_master
    @al = create_item
  end

  describe "generate a text field containing data to be signed" do

    it "generates a reference document for signature" do

    end

    it "removes the fields that are hidden based on conditional rules" do

    end

    it "adds some text about what is being signed" do

    end

    it "adds the user email address to the end of the document" do

    end


  end

  describe "at time of applying the signature" do

    it "adds a date and time to end of the document and saves the timestamp for the salt" do

    end

    it "adds document unique code to the end to act as a salt " do
      # salt is user.id, record type being signed, field name being signed, record id and ms timestamp
    end

    it "generates a hash digest using the whole document + a pepper, adds the hash to the document and its own field" do

    end

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
