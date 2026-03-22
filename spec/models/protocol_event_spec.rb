require 'rails_helper'

describe Classification::ProtocolEvent do
  include ModelSupport
  include ProtocolEventSupport

  describe 'definition' do
    before :each do
      seed_database
      create_user
      create_admin

      updates_protocol_id = Classification::Protocol.record_updates_protocol.id
      Classification::ProtocolEvent.active.each do |p|
        next if p.protocol.id == updates_protocol_id

        p.disabled = true
        p.sub_process ||= Classification::SubProcess.enabled.first
        p.current_admin = @admin
        p.save!
      end

      expect(Classification::ProtocolEvent.active.reload.find_by(name: 'created player info')).not_to be nil

      create_master
      @protocol = Classification::Protocol.create! name: "QA#{rand 1000}", position: rand(10_000), disabled: false, current_admin: @admin
      @sub_process = @protocol.sub_processes.create! name: 'SP1', disabled: false, current_admin: @admin
      create_items :list_valid_attribs

      @protocol = Classification::Protocol.create! name: "QB#{rand 1000}", position: rand(10_000), disabled: false, current_admin: @admin
      @sub_process = @protocol.sub_processes.create! name: 'SP2', disabled: false, current_admin: @admin
      @sub_process = @protocol.sub_processes.create! name: 'SP3', disabled: false, current_admin: @admin
      create_items :list_valid_attribs
    end

    it 'allows multiple Classification::Protocol Events to be created and returned in order based on name' do
      expect(@created_count).to eq @list.length

      # Verify that the database returns items in the order defined by its default_scope (ORDER BY name)
      # Note: Database collation may differ from Ruby string comparison
      names = Classification::ProtocolEvent.active.pluck(:name)
      expected_names = Classification::ProtocolEvent.active.order(:name).pluck(:name)

      expect(names).to eq expected_names
      expect(names).not_to be_empty
    end

    it 'can return active items only' do
      pa = Classification::ProtocolEvent.active
      expect(pa.length).to be > 0
      res = pa.select { |p| p.disabled }
      expect(res.length).to eq 0
    end

    it 'can only have name updated by an admin' do
      pa = Classification::ProtocolEvent.active.first
      pa.name = 'new name by me'

      expect(pa.save).to be false

      pa.current_admin = @admin
      expect(pa.save!).to be true

      pa.reload
      expect(pa.name).to eq 'new name by me'
    end

    it 'belongs to a protocol' do
      pa = @sub_process.protocol_events.active

      expect(pa.length).to be < Classification::ProtocolEvent.all.length
    end
  end
end
