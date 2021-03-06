require 'rails_helper'

RSpec.describe PlayerContact, type: :model do

  include ModelSupport
  include PlayerContactSupport


  def item
    @player_contact
  end



  describe "Check for appropriate data construction" do

    before :each do
      seed_database
      create_user
      create_master

      Seeds::GeneralSelections.create_player_contacts_source
    end

    it "requires data to be entered" do

      pc = @master.player_contacts.build data: nil, rec_type: 'email', rank: PlayerContact::PrimaryRank
      expect(pc.save).to equal false

      pc.data = 'test@email.com'
      expect(pc.save).to equal(true), "Something went wrong saving. Errors: #{pc.errors.inspect}"
    end

    it "requires rank to be entered" do
      pc = @master.player_contacts.build data: 'test@email.com', rec_type: 'email'
      expect(pc.save).to equal false
      pc.rank  = PlayerContact::PrimaryRank
      expect(pc.save).to equal(true), "Something went wrong saving. Errors: #{pc.errors.inspect}"

    end

    it "validates email address" do
      pc = @master.player_contacts.build data: 'test@email', rec_type: 'email', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq false
      expect(pc.errors.messages).to have_key(:data), "Data errors: #{pc.errors.messages.inspect}"
      pc.data ='(617)773-9182'
      expect(pc.save).to eq false
      expect(pc.errors.messages).to have_key(:data), "Data errors: #{pc.errors.messages.inspect}"


      pc.data ='test@email.com'
      expect(pc.save).to eq true

    end

    it "reformats phone number" do
      data = ""
      pc = @master.player_contacts.build data: data, rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq false
      expect(pc.data).to eq ''

      data = "123456789 "
      pc = @master.player_contacts.build data: data, rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq false
      expect(pc.data).to eq "123456789 "

      data = "1234567890"
      pc = @master.player_contacts.build data: data, rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq true
      expect(pc.data).to eq '(123)456-7890'

      # The order of attributes may matter. Try reversing rec_type and data
      data = "(123)4567890"
      pc = @master.player_contacts.build rec_type: 'phone', data: data, rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq true
      expect(pc.data).to eq '(123)456-7890'

      data = "123-456 7890"
      pc = @master.player_contacts.build rec_type: 'phone', data: data, rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq true
      expect(pc.data).to eq '(123)456-7890'

      data = "1234567890 x123"
      pc = @master.player_contacts.build data: data, rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq true
      expect(pc.data).to eq '(123)456-7890 x123'

      data = "a1234567890"
      pc = @master.player_contacts.build data: data, rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq false
      expect(pc.data).to eq "a1234567890"

      data = "123b4567890"
      pc = @master.player_contacts.build data: data, rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq false
      expect(pc.data).to eq "123b4567890"

      data = "123.456.7890"
      pc = @master.player_contacts.build data: data, rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq true
      expect(pc.data).to eq '(123)456-7890'

      data = "123.456.7890.454"
      pc = @master.player_contacts.build data: data, rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq true
      expect(pc.data).to eq '(123)456-7890 .454'


    end

    it "validates phone number" do
      pc = @master.player_contacts.build data: '6172526a172', rec_type: 'phone', rank:  PlayerContact::SecondaryRank
      expect(pc.save).to eq false
      expect(pc.errors.messages).to have_key(:data), "Data errors: #{pc.errors.messages.inspect}"
      pc.data ='test@email.com'
      expect(pc.save).to eq false
      expect(pc.errors.messages).to have_key(:data), "Data errors: #{pc.errors.messages.inspect}"


      pc.data ='(617)782-2382'
      expect(pc.save).to eq true
      expect(pc.data).to eq '(617)782-2382'

      pc.data ='(617)782-2382 ext 15521'
      expect(pc.save).to eq true
      expect(pc.data).to eq '(617)782-2382 ext 15521'
    end


    it "validates correct source" do

      gs = Classification::GeneralSelection.active.where(item_type: 'player_contacts_source')

      expect(gs.length).to be > 0
      expect(gs.first.value).to_not be_nil


      pc = @master.player_contacts.build data: '(617)773-9182', rec_type: 'phone', rank:  PlayerContact::SecondaryRank, source: 'bad'
      expect(pc.save).to eq false
      expect(pc.errors.messages).to have_key(:source), "Data errors: #{pc.errors.messages.inspect}"

      pc = @master.player_contacts.build data: '(617)773-9182', rec_type: 'phone', rank:  PlayerContact::SecondaryRank, source: gs.first.value
      expect(pc.save).to eq true
      expect(pc.source).to_not be_nil

      pc = @master.player_contacts.build data: '(617)773-9182', rec_type: 'phone', rank:  PlayerContact::SecondaryRank, source: gs.last.value
      expect(pc.save).to eq true
      expect(pc.source).to_not be_nil
    end


    it "updates rank update across all records based on primary being set" do
      pcs = []

      pcs << @master.player_contacts.create(data: 'test@email.com', rec_type: 'email', rank: PlayerContact::SecondaryRank) #0
      pcs << @master.player_contacts.create(data: 'test2@email.com', rec_type: 'email', rank: PlayerContact::PrimaryRank) #1
      pcs << @master.player_contacts.create(data: 'test3@email.com', rec_type: 'email', rank: PlayerContact::InactiveRank) #2
      pcs << @master.player_contacts.create(data: '(617)794-1111', rec_type: 'phone', rank: PlayerContact::InactiveRank) #3
      pcs << @master.player_contacts.create(data: '(617)794-1113', rec_type: 'phone', rank: PlayerContact::SecondaryRank) #4
      pcs << @master.player_contacts.create(data: '(617)794-1115', rec_type: 'phone', rank: PlayerContact::PrimaryRank) #5

      expect(pcs[0].rank).to eq PlayerContact::SecondaryRank
      expect(pcs[1].rank).to eq PlayerContact::PrimaryRank
      expect(pcs[2].rank).to eq PlayerContact::InactiveRank
      expect(pcs[3].rank).to eq PlayerContact::InactiveRank
      expect(pcs[4].rank).to eq PlayerContact::SecondaryRank
      expect(pcs[5].rank).to eq PlayerContact::PrimaryRank

      pcs << @master.player_contacts.create(data: 'test4@email.com', rec_type: 'email', rank: PlayerContact::PrimaryRank)

      pcs.each {|a| a.reload }


      expect(pcs[0].rank).to eq PlayerContact::SecondaryRank
      expect(pcs[1].rank).to eq(PlayerContact::SecondaryRank), "Item #{pcs[1].id} should have changed to secondary. It didn't."
      expect(pcs[2].rank).to eq PlayerContact::InactiveRank
      #No changes in non-email types
      expect(pcs[3].rank).to eq PlayerContact::InactiveRank
      expect(pcs[4].rank).to eq PlayerContact::SecondaryRank
      expect(pcs[5].rank).to eq PlayerContact::PrimaryRank

      # New one should be the primary email now
      expect(pcs[6].rank).to eq PlayerContact::PrimaryRank

      # Add a new primary phone
      pcs << @master.player_contacts.create(data: '(716)718-1222', rec_type: 'phone', rank: PlayerContact::PrimaryRank)
      pcs.each {|a| a.reload }


      expect(pcs[0].rank).to eq PlayerContact::SecondaryRank
      expect(pcs[1].rank).to eq(PlayerContact::SecondaryRank)
      expect(pcs[2].rank).to eq PlayerContact::InactiveRank
      #No changes in non-email types
      expect(pcs[3].rank).to eq PlayerContact::InactiveRank
      expect(pcs[4].rank).to eq PlayerContact::SecondaryRank
      expect(pcs[5].rank).to eq(PlayerContact::SecondaryRank), "Item #{pcs[5].id} should have changed to secondary. It didn't."
      expect(pcs[6].rank).to eq PlayerContact::PrimaryRank

      # New one
      expect(pcs[7].rank).to eq PlayerContact::PrimaryRank

      # Now test updated items, rather than new ones
      pcs[0].rank = PlayerContact::InactiveRank
      pcs[0].master.current_user = @user
      pcs[0].save!

      expect(pcs[0].rank).to eq(PlayerContact::InactiveRank), "Item #{pcs[0].id} should have been set to inactive. It wasn't."

      pcs[2].rank = PlayerContact::PrimaryRank
      pcs[2].master.current_user  = @user
      pcs[2].save!

      pcs.each {|a| a.reload }

      expect(pcs[0].rank).to eq(PlayerContact::InactiveRank), "Item #{pcs[0].id} should have been set to inactive. It wasn't."
      expect(pcs[1].rank).to eq(PlayerContact::SecondaryRank)
      expect(pcs[2].rank).to eq(PlayerContact::PrimaryRank), "Item #{pcs[2].id} should have been set to primary. It wasn't."
      expect(pcs[3].rank).to eq PlayerContact::InactiveRank
      expect(pcs[4].rank).to eq PlayerContact::SecondaryRank
      expect(pcs[5].rank).to eq PlayerContact::SecondaryRank
      expect(pcs[6].rank).to eq(PlayerContact::SecondaryRank), "Item #{pcs[6].id} should have changed to secondary. It didn't."
      expect(pcs[7].rank).to eq(PlayerContact::PrimaryRank)

    end

    it "generates rec type associations" do
      pcs = []

      pcs << @master.player_contacts.create(data: 'test@email.com', rec_type: 'email', rank: PlayerContact::SecondaryRank) #0
      pcs << @master.player_contacts.create(data: 'test2@email.com', rec_type: 'email', rank: PlayerContact::PrimaryRank) #1
      pcs << @master.player_contacts.create(data: '(617)794-1111', rec_type: 'phone', rank: PlayerContact::InactiveRank) #2
      pcs << @master.player_contacts.create(data: '(617)794-1113', rec_type: 'phone', rank: PlayerContact::SecondaryRank) #3
      pcs << @master.player_contacts.create(data: '(617)794-1115', rec_type: 'phone', rank: PlayerContact::PrimaryRank) #4


      expect(@master.player_contact_phones.length).to eq 3
      expect(@master.player_contact_emails.length).to eq 2

      expect(@master.player_contact_phones.first.data).to eq pcs[4].data
    end

  end

  it_behaves_like 'a standard user model'
end
