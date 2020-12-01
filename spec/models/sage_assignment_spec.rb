# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SageAssignment', type: :model do
  include ModelSupport
  include SageAssignmentSupport

  describe 'SageAssignment' do
    before :each do
      seed_database
      create_user
      setup_access :sage_assignments
      @alt_master = create_master

      create_master
    end

    it 'allows multiple SageAssignment records to be created, then to be assigned' do
      # create_items :list_valid_attribs, @master

      res = SageAssignment.generate_ids(@admin, 100)

      @created_count = res.length

      expect(@created_count).to be > 90 # allow for a few to drop out due to existing in the db already

      list = []
      10.times do
        s = @master.sage_assignments.build sage_id: ''
        s.save!
        list << s
      end

      num = 0
      # Step through the full set of sage assignments and compare it to those assigned to this master
      @master.sage_assignments.unscope(:order).order(:id).each do |s|
        expect(s.sage_id).to eq list[num].sage_id
        num += 1
        break if num > list.length
      end
    end

    it 'only allows sage_assignment IDs that have been pregenerated' do
      res = SageAssignment.generate_ids(@admin, 100)

      create_items :list_invalid_attribs, @master, true
      check_all_records_failed
    end

    it 'prevents assignments from being edited' do
      @master.sage_assignments.unscope(:order).order(:id).each do |s|
        s.sage_id = SageAssignment.generate_random_id.to_s
        res = s.save
        expect(res.errors).to have_key(:sage_id)
        expect(res.errors[:sage_id]).to eq 'can not be changed'
      end

      @master.sage_assignments.unscope(:order).order(:id).each do |s|
        s.master_id = @alt_master
        res = s.save
        expect(res.errors).to have_key(:sage_id)
        expect(res.errors[:master]).to eq 'record this sage ID is associated with can not be changed'
      end
    end

    it 'provides error when no unassigned IDs remain' do
      SageAssignment.unassigned.each do
        s = @master.sage_assignments.build sage_id: ''
        s.save!
      end

      expect do
        @master.sage_assignments.build sage_id: ''
      end.to raise_error(Dynamic::ExternalIdImplementer::NoUnassignedAvailable, 'No available IDs for assignment')
    end
  end

  # it_behaves_like 'a standard user model'
end
