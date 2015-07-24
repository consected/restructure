require 'rails_helper'

RSpec.describe Address, type: :model do
  
  include ModelSupport
  include AddressSupport
  
  ObjectClass = Address
  def item
    @address
  end
  
  ObjectsSymbol = ObjectClass.to_s.underscore.pluralize.to_sym
  ObjectSymbol = ObjectClass.to_s.underscore.to_sym
  def item_id
    item.to_param
  end
  
  
  describe "Check for appropriate data construction" do
    
    before :each do
      seed_database
      create_user
      create_master      
    end

    
    
    it "requires rank to be entered" do
      address = @master.addresses.build street: '123 main st', city: 'boston', zip: '01234'
      expect(address.save).to equal false
      address.rank  = Address::PrimaryRank
      expect(address.save).to equal(true), "Something went wrong saving. Errors: #{address.errors.inspect}"
      
    end
    
    it "validates zip" do
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

    
    it "updates rank update across all records based on primary being set" do
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
  
  
end
