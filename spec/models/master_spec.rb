# frozen_string_literal: true

require 'rails_helper'

require 'support/pro_info_support'

RSpec.describe Master, type: :model do
  include ModelSupport
  include MasterDataSupport

  before(:example) do
    # seed_database

    create_data_set

    add_app_config @user.app_type, 'create master with', 'player_info'
    # Cleanup to get started
    Master.reset_external_id_matching_fields!
  end

  it 'should create a master successfully' do
    expect(@master).to be_a Master
    expect(@master.id).to_not be nil
    expect(@full_master_record.player_infos.length).to eq 1
    expect(@full_master_record.pro_infos.length).to eq 1

    pi1 = @full_master_record.player_infos.first
    expect(first_names).to include pi1.first_name.capitalize
    expect(pi1.user.email).to eq gen_username("#{full_master_number + @user_start}-mds1-")
    expect(pi1.user.email).to_not be nil

    pro1 = @full_master_record.pro_infos.first
    expect(first_names).to include pro1.first_name.capitalize
    expect(pro1.user.email).to eq gen_username("#{full_master_number + @user_start}-mds1-")
  end

  it 'should see results of database triggers ok' do
    pi1 = @full_master_record.player_infos.first
    pro1 = @full_master_record.pro_infos.first
    expect(@full_master_record.pro_id).to eq pro1.pro_id
    expect(@full_master_record.rank).to eq pi1.rank
  end

  it 'adds an MSID value within a DB trigger' do
    # This has been put on ice. The original functionality has been commented out below

    # Create a master record without an MSID
    new_master = Master.new
    new_master.current_user = @user
    new_master.save!

    # Check it was setup correctly
    expect([11, 12]).not_to include new_master.rank
    expect(new_master.msid).to be nil

    # Now set a low rank, and expect the MSID NOT to be set
    new_master.rank = 0
    new_master.save!
    expect(new_master.msid).to be nil

    # # Now set a rank, and expect the MSID to be set
    # new_master.rank = 11
    # new_master.save!
    # expect(new_master.msid).not_to be nil

    # # Create a new master with a rank that creates an MSID
    # new_master = Master.new
    # new_master.current_user = @user
    # new_master.rank = 12
    # new_master.save!

    # msid = new_master.msid
    # expect(msid).not_to be nil

    # # Check the MSID did not change once an MSID has been assigned
    # new_master.rank = 11
    # new_master.save!
    # expect(new_master.msid).to eq new_master.msid
  end

  it "should ensure users can't change data" do
    @master.pro_id = rand 1_000_000
    expect(@master.save).to be false
    @master.msid = rand 1_000_000
    expect(@master.save).to be false

    @master.pro_info_id = nil
    expect(@master.save).to be false
  end

  it 'should create a master and player like a user would, with the player info embedded in the master' do
    m = Master.create_master_record(@user)
    expect(m).to be_a Master
    expect(m).to be_persisted
    expect(m.player_infos.length).to eq 1
    expect(m.player_infos.first).to be_a PlayerInfo
    expect(m.player_infos.first).to be_persisted
  end

  it 'should support simple search across player and pro info tables' do
    params = { general_infos_attributes: { '0' => { first_name: @full_player_info.first_name.downcase } } }
    res = Master.search_on_params params

    # We can expect at least two records to be returned
    expect(res.length).to be >= 2
    # Since we forced the reference record to be the only one ranked so it appears first, we can compare against the first item in the results
    # independent of how many are actually returned
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info

    # The user should match that we used to create the item
    expect(res.first.player_infos.first.user.email).to eq gen_username("#{full_master_number + @user_start}-mds1-")
  end

  it 'should support simple search across matching start of first name or nickname' do
    params = { general_infos_attributes: { '0' => { first_name: @full_player_info.first_name.downcase[0..2] } } }
    res = Master.search_on_params params

    # Since we forced the reference record to be the only one ranked so it appears first, we can compare against the first item in the results
    # independent of how many are actually returned
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info

    params = { general_infos_attributes: { '0' => { first_name: @full_player_info.nick_name.downcase[0..2] } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info

    params = { general_infos_attributes: { '0' => { first_name: 'willnotmatch' } } }
    res = Master.search_on_params params
    expect(res.length).to eq 0

    params = { general_infos_attributes: { '0' => { first_name: @full_pro_info.first_name.downcase[0..3] } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info
  end

  it 'should support simple search across matching last name' do
    params = { general_infos_attributes: { '0' => { last_name: 'willnotmatch' } } }
    res = Master.search_on_params params
    expect(res.length).to eq 0

    params = { general_infos_attributes: { '0' => { last_name: @full_player_info.last_name } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info

    params = { general_infos_attributes: { '0' => { last_name: @full_pro_info.last_name } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info
  end

  it 'should support simple search across start and end year' do
    params = { general_infos_attributes: { '0' => { start_year: 1800, end_year: 1801 } } }
    res = Master.search_on_params params
    expect(res.length).to eq 0

    params = { general_infos_attributes: { '0' => { start_year: @full_player_info.start_year,
                                                    end_year: @full_player_info.end_year } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info

    params = { general_infos_attributes: { '0' => { start_year: @full_pro_info.start_year,
                                                    end_year: @full_pro_info.end_year } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info
  end

  it 'should support simple search for birth and death dates' do
    params = { general_infos_attributes: { '0' => { birth_date: Time.now - 100.years,
                                                    death_date: Time.now - 100.years } } }
    res = Master.search_on_params params
    expect(res.length).to eq 0

    params = { general_infos_attributes: { '0' => { birth_date: @full_player_info.birth_date,
                                                    death_date: @full_player_info.death_date } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info

    params = { general_infos_attributes: { '0' => { birth_date: @full_pro_info.birth_date,
                                                    death_date: @full_pro_info.death_date } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info
  end

  it 'should support simple search for college' do
    params = { general_infos_attributes: { '0' => { college: 'willnotmatch' } } }
    res = Master.search_on_params params
    expect(res.length).to eq 0

    params = { general_infos_attributes: { '0' => { college: @full_player_info.college } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info

    params = { general_infos_attributes: { '0' => { college: @full_pro_info.college } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info
  end

  it 'should support simple search for several attributes' do
    params = { general_infos_attributes: { '0' => { college: @full_player_info.college,
                                                    last_name: @full_pro_info.last_name, start_year: @full_player_info.start_year } } }
    res = Master.search_on_params params
    expect(res.first).to eq(@full_master_record), master_error(res, params)
    expect(res.first.player_infos.first).to eq @full_player_info
    expect(res.first.pro_infos.first).to eq @full_pro_info
    expect(res.length).to be >= 2

    p = params[:general_infos_attributes]['0']
    check = true

    # Check all the search attributes match either player or pro info

    res.each do |r|
      pi = r.player_infos.first
      pro = r.pro_infos.first
      check ||= (pi.college == p[:college]) || (pro.college == p[:college])
      check ||= (pi.last_name == p[:last_name]) || (pro.last_name == p[:last_name])
      check ||= (pi.start_year == p[:start_year]) || (pro.start_year == p[:start_year])
    end

    expect(check).to be true
  end

  describe 'contact search' do
    before(:example) do
      create_data_set
      @contact_1 = @full_master_record.player_contacts.create!(data: '(617)794-1213', rec_type: 'phone', rank: 10)
      @contact_2 = @full_master_record.player_contacts.create!(data: '(617)223-1213 ext 1621', rec_type: 'phone',
                                                               rank: 5)
      @contact_3 = @full_master_record.player_contacts.create!(data: 'some.email@testdomain.com', rec_type: 'email',
                                                               rank: 10)
    end

    it 'should search ok' do
      params = { general_infos_attributes: { '0' => { college: @full_player_info.college } } }
      res = Master.search_on_params params
      expect(res.first).to eq(@full_master_record), master_error(res, params)
    end

    it 'should support search for formatted phone number' do
      params = { general_infos_attributes: { '0' => { contact_data: 'willnotmatch' } } }
      res = Master.search_on_params params
      expect(res.length).to eq 0

      params = { general_infos_attributes: { '0' => { contact_data: @contact_1.data } } }
      res = Master.search_on_params params
      expect(res.length).to eq 1
      expect(res.first).to eq(@full_master_record), master_error(res, params)
      expect(res.first.player_infos.first).to eq @full_player_info
      expect(res.first.pro_infos.first).to eq @full_pro_info
    end
    it 'should support search for partial phone' do
      params = { general_infos_attributes: { '0' => { contact_data: @contact_1.data[0..6] } } }
      res = Master.search_on_params params
      expect(res.length).to eq 1
      expect(res.first).to eq(@full_master_record), master_error(res, params)
      expect(res.first.player_infos.first).to eq @full_player_info
      expect(res.first.pro_infos.first).to eq @full_pro_info
    end

    it 'should support search for unformatted phone ' do
      # Check we can search on data without formatting
      params = { general_infos_attributes: { '0' => { contact_data: @contact_2.data.gsub(/\W+/, '')[0..9] } } }
      res = Master.search_on_params params
      expect(res.first).to eq(@full_master_record), master_error(res, params)
      expect(res.first.player_infos.first).to eq @full_player_info
      expect(res.first.pro_infos.first).to eq @full_pro_info
    end
    it 'should support search for unformatted partial phone ' do
      params = { general_infos_attributes: { '0' => { contact_data: @contact_3.data.gsub(/\W+/, '') } } }
      res = Master.search_on_params params
      expect(res.first).to eq(@full_master_record), master_error(res, params)
      expect(res.first.player_infos.first).to eq @full_player_info
      expect(res.first.pro_infos.first).to eq @full_pro_info
    end
    it 'should support search for full email' do
      params = { general_infos_attributes: { '0' => { contact_data: @contact_3.data } } }
      res = Master.search_on_params params
      expect(res.first).to eq(@full_master_record), master_error(res, params)
      expect(res.first.player_infos.first).to eq @full_player_info
      expect(res.first.pro_infos.first).to eq @full_pro_info
    end
    it 'should support search for partial email' do
      params = { general_infos_attributes: { '0' => { contact_data: @contact_3.data.split('@').first } } }
      res = Master.search_on_params params
      expect(res.first).to eq(@full_master_record), master_error(res, params)
      expect(res.first.player_infos.first).to eq @full_player_info
      expect(res.first.pro_infos.first).to eq @full_pro_info
    end

    it 'provides alternative ids' do
      ids = @master.alternative_ids
      expect(ids.keys).to include :msid

      t = Benchmark.realtime do
        100.times do
          ids = @master.alternative_ids
          expect(ids.keys).to include :msid
        end
      end

      puts "Took #{t} seconds"
      expect(t).to be < 2
    end
  end
end
