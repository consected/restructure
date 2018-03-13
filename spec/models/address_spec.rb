require 'rails_helper'

RSpec.describe Address, type: :model do

  include ModelSupport
  include AddressSupport


  describe "Address" do

    before :each do
      seed_database
      create_user
      create_master
      setup_access :addresses
    end



    it "allows country US to save with rank set" do
      address = @master.addresses.build rank: 5, street: '123 main st', city: 'boston', zip: '01234', country: 'us'
      expect(address.save).to equal(true), "Failed to save address: #{address.errors.messages.inspect}"
    end
    it "prevents non-US country to save with without region or postal_code set" do
      address = @master.addresses.build rank: 5, street: '123 main st', city: 'boston', country: 'ca'
      expect(address.save).to equal false
      expect(address.errors.messages).to have_key(:country)
    end
    it "allows non-US country to save with with region or postal_code or both set" do
      address = @master.addresses.build rank: 5, street: '123 main st', city: 'toronto', region: 'ontario', country: 'ca'
      expect(address.save).to equal true
      address = @master.addresses.build rank: 5, street: '123 main st', city: 'toronto', postal_code: 'ON5 2GH', country: 'ca'
      expect(address.save).to equal true
      address = @master.addresses.build rank: 5, street: '123 main st', city: 'toronto', region: 'ontario', postal_code: 'ON5 2GH', country: 'ca'
      expect(address.save).to equal true
    end

    it "allows non-US country to save with zip and state set, but clears the data so that zip and state are empty when retrieved" do
      address = @master.addresses.build rank: 5, street: '123 main st', city: 'toronto', zip: '12671', state: 'ma', country: 'ca', region: 'ontario', postal_code: 'ON5 2GH'
      expect(address.save).to equal true
      address.reload
      expect(address.state).to be nil
      expect(address.zip).to be nil
      expect(address.region).to eq 'ontario'
    end

    it "allows US country to save with region and postal_code set, but clears the data so that region and postal_code are empty when retrieved" do
      address = @master.addresses.build rank: 5, street: '123 main st', city: 'toronto', zip: '12671', state: 'ma', country: 'us', region: 'ontario', postal_code: 'ON5 2GH'
      expect(address.save).to equal true
      address.reload
      expect(address.region).to be nil
      expect(address.postal_code).to be nil
      expect(address.zip).to eq '12671'
    end



    it "validates zip is 5 digit or 5+4 digit format" do
      address = @master.addresses.build street: '123 main st', city: 'boston', rank: 10, zip: '123AB'
      expect(address.save).to eq false
      expect(address.errors.messages).to have_key(:zip), "Data errors: #{address.errors.messages.inspect}"
      address.zip ='1234'
      expect(address.save).to eq false
      expect(address.errors.messages).to have_key(:zip), "Data errors: #{address.errors.messages.inspect}"
      address.zip ='12345-'
      expect(address.save).to eq false
      expect(address.errors.messages).to have_key(:zip), "Data errors: #{address.errors.messages.inspect}"
      address.zip ='12345-123A'
      expect(address.save).to eq false
      expect(address.errors.messages).to have_key(:zip), "Data errors: #{address.errors.messages.inspect}"

      address.zip ='02345-2123'
      expect(address.save).to eq true

      address.zip ='00233-0283'
      expect(address.save).to eq true

    end

    it "validates correct source" do

      gs = GeneralSelection.where(item_type: 'addresses_source').where('disabled is null OR disabled = true')

      expect(gs.length).to be > 0
      expect(gs.first.value).to_not be_nil


      address = @master.addresses.build street: '123 main st', city: 'boston', rank: 10, zip: '12300', source: 'bad'
      expect(address.save).to eq false
      expect(address.errors.messages).to have_key(:source), "Data errors: #{address.errors.messages.inspect}"

      address = @master.addresses.build street: '123 main st', city: 'boston', rank: 10, zip: '12300', source: gs.first.value
      expect(address.save).to eq true
      expect(address.source).to_not be_nil

      address = @master.addresses.build street: '123 main st', city: 'boston', rank: 10, zip: '12300', source: gs.last.value
      expect(address.save).to eq true
      expect(address.source).to_not be_nil
    end

    it "requires rank to be entered" do
      address = @master.addresses.build street: '123 main st', city: 'boston', zip: '01234'
      expect(address.save).to equal false
      address.rank  = Address::PrimaryRank
      expect(address.save).to equal(true), "Something went wrong saving. Errors: #{address.errors.inspect}"

    end

    it "updates rank update across all records based on primary being set so that only primary record can be set and any existing primary ranks will be changed to secondary" do
      addresses = []

      addresses << @master.addresses.create(street: '123 main st', city: 'boston', zip: '01234', rank: Address::SecondaryRank) #0
      addresses << @master.addresses.create(street: '125 main st', city: 'cambridge', zip: '21234',  rank: Address::PrimaryRank) #1
      addresses << @master.addresses.create(street: '55 main st', street2: 'apt444', street3: '(rear of building)',  city: 'portland', zip: '22221-9172',  rank: Address::InactiveRank) #2

      expect(addresses[0].rank).to eq Address::SecondaryRank
      expect(addresses[1].rank).to eq Address::PrimaryRank
      expect(addresses[2].rank).to eq Address::InactiveRank

      addresses << @master.addresses.create(street: '77 main st', city: 'boston', zip: '01234',  rank: Address::PrimaryRank)

      addresses.each {|a| a.reload }


      expect(addresses[0].rank).to eq Address::SecondaryRank
      expect(addresses[1].rank).to eq(Address::SecondaryRank), "Item #{addresses[1].id} should have changed to secondary. It didn't."
      expect(addresses[2].rank).to eq Address::InactiveRank

      # New one should be the primary email now
      expect(addresses[3].rank).to eq Address::PrimaryRank

      # Now test updated items, rather than new ones
      addresses[0].rank = Address::InactiveRank
      addresses[0].master.current_user = @user
      addresses[0].save!

      expect(addresses[0].rank).to eq(Address::InactiveRank), "Item #{addresses[0].id} should have been set to inactive. It wasn't."

      addresses[2].rank = Address::PrimaryRank
      addresses[2].master.current_user  = @user
      addresses[2].save!

      addresses.each {|a| a.reload }

      expect(addresses[0].rank).to eq(Address::InactiveRank), "Item #{addresses[0].id} should have been set to inactive. It wasn't."
      expect(addresses[1].rank).to eq(Address::SecondaryRank)
      expect(addresses[2].rank).to eq(Address::PrimaryRank), "Item #{addresses[2].id} should have been set to primary. It wasn't."
      expect(addresses[3].rank).to eq(Address::SecondaryRank), "Item #{addresses[3].id} should have changed to secondary. It didn't."

    end


  end

  it_behaves_like 'a standard user model'


end
