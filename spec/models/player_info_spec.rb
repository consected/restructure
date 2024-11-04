# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerInfo, type: :model do
  include ModelSupport
  include PlayerInfoSupport
  before(:example) do
    create_user

    create_items

    @master = Master.create current_user: @user

    @created_count = 0

    lnew = { first_name: 'phil', last_name: 'good', middle_name: 'andrew', nick_name: 'mitch', birth_date: Time.now - 60.years, source: 'nflpa' }

    @list << lnew

    @player_info = @master.player_infos.build lnew
    @created_count += 1
    res = @player_info.save!
    @created_items << @player_info if res
  end

  it 'should store all information related to a player' do
    create_items

    expect(@created_count).to eq(@list.length), "Expected #{@list.length} items to be created. Got #{@created_count}. Exceptions: #{@exceptions}"

    num = 0

    @list.each do |l|
      pi = @created_items[num]
      expect(pi).to be_a PlayerInfo
      expect(pi.id).to_not be_nil
      expect(pi.user_id).to eq @user.id
      expect(pi.master_id).to_not be_nil

      l.each do |k, v|
        if v.is_a? Time
          expect(pi.attributes[k.to_s].to_datetime).to be_within(1.hour).of(v.to_datetime), "Date Attribute #{k} in player info #{pi.id} did not match the expected value #{v}. Got #{pi.attributes[k.to_s]}"
        else
          expect(pi.attributes[k.to_s]).to eq(v), "(#{v.class}) Attribute #{k} in player info #{pi.id} did not match the expected value #{v}. Got #{pi.attributes[k.to_s]}"
        end
      end
      num += 1
    end
  end

  it 'should allow changes to player info attributes' do
    res = @player_info.update first_name: 'charles'
    expect(res).to be true

    @player_info.reload
    expect(@player_info.first_name).to eq 'charles'
  end

  it 'checks whether birth date is before today' do
    @player_info.birth_date = DateTime.now + 1.day
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"birth date"), "Errors should contain birth date: #{@player_info.errors.inspect}"
  end

  it 'checks whether death date is before today' do
    @player_info.death_date = DateTime.now + 1.day
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"death date"), "Errors should contain death date: #{@player_info.errors.inspect}"
  end

  it 'checks whether death date is before birth date' do
    @player_info.birth_date = DateTime.now - 10.years
    @player_info.death_date = @player_info.birth_date - 1.day
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"birth date"), "Errors should contain dates: #{@player_info.errors.inspect}"
  end

  it 'checks whether start year is after this year' do
    @player_info.start_year = Time.now.year + 2
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"start year"), "Errors should contain start year: #{@player_info.errors.inspect}"
  end

  it 'checks whether start year is at least 19 years after and less than 30 years after birth date' do
    @player_info.birth_date = Time.now - 50.years
    @player_info.start_year = @player_info.birth_date.year + 19
    expect(@player_info.save).to be true
    @player_info.start_year = @player_info.birth_date.year + 29
    expect(@player_info.save).to be true

    @player_info.start_year = @player_info.birth_date.year + 30
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"start year"), "Errors should contain start year: #{@player_info.errors.inspect}"

    @player_info.start_year = @player_info.birth_date.year + 18
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"start year"), "Errors should contain start year: #{@player_info.errors.inspect}"
  end

  it 'checks whether end year is after this year' do
    @player_info.end_year = Time.now.year + 2
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"end year"), "Errors should contain end year: #{@player_info.errors.inspect}"
  end

  it 'checks whether end year is before start year' do
    @player_info.start_year = Time.now.year - 20
    @player_info.end_year = @player_info.start_year - 1
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"start year"), "Errors should contain years: #{@player_info.errors.inspect}"
  end

  it "checks user can't change source" do
    @player_info.source = 'nflpa2'

    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:source), "Errors should contain source: #{@player_info.errors.inspect}"
  end

  it "calculates the player's age" do
    @player_info.birth_date = Time.now - 50.years
    age = @player_info.subject_age
    expect(age).to eq 50

    @player_info.birth_date = Time.now - 30.years + 1.day
    age = @player_info.subject_age
    expect(age).to eq 29
  end

  #  it "presents an error if the birth_date is not set and the rank is not set to 881" do
  #    orig = Time.now - 60.years
  #    @player_info.birth_date = nil
  #    @player_info.rank = 881
  #    expect(@player_info.save).to be true
  #
  #    @player_info.rank = 888
  #    expect(@player_info.save).to be false
  #    expect(@player_info.errors.messages).to have_key(:"birth date")
  #
  #    @player_info.birth_date = orig
  #    expect(@player_info.save).to be true
  #
  #
  #  end

  it_behaves_like 'a standard user model'
end
