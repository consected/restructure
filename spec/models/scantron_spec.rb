# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scantron', type: :model do
  include ModelSupport
  include ScantronSupport

  describe 'Scantron' do
    before :each do
      seed_database
      create_user
      setup_access :scantrons
      create_master
    end

    it 'allows multiple Scantron records to be created, with just a scantron ID' do
      create_items :list_valid_attribs, @master

      expect(@created_count).to be > 0

      num = 0
      @master.scantrons.unscope(:order).order(:id).each do |s|
        expect(s.scantron_id).to eq @list[num][:scantron_id]
        num += 1
      end
    end

    it 'prevents pre-generation of scantron ids' do
      res = begin
        current_scantron_model.generate_ids(@admin, 100)
      rescue StandardError
        nil
      end
      expect(res).to be nil
    end

    it 'only allows scantron IDs that are positive integers (greater than 0) with up to 6 digits' do
      create_items :list_invalid_attribs, @master, true

      check_all_records_failed
    end
  end

  it_behaves_like 'a standard user model'
end
