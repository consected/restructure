require 'rails_helper'

describe Classification::Protocol do
  include ModelSupport
  include ProtocolSupport
  describe 'definition' do
    before :each do
      seed_database
      create_user
      create_admin
      create_master
      create_items :list_valid_attribs
    end

    it 'allows multiple Protocols to be created and returned in order based on position' do
      expect(@created_count).to eq @list.length

      Classification::Protocol.all.each do |p|
        p.position = rand 100
        p.current_admin = @admin
        p.save!
      end

      prev_pos = -1
      Classification::Protocol.all.each do |p|
        expect(p.position).to be >= prev_pos
        prev_pos = p.position if p.position
      end

      expect(prev_pos).to be > 0
    end

    it 'can return active items only' do
      pa = Classification::Protocol.active
      expect(pa.length).to be > 0
      res = pa.select { |p| p.disabled }
      expect(res.length).to eq 0
    end

    it 'can only have name updated by an admin' do
      pa = Classification::Protocol.active.first
      pa.name = 'new name by me'

      expect(pa.save).to be false

      pa.current_admin = @admin
      expect(pa.save).to be true

      pa.reload
      expect(pa.name).to eq 'new name by me'
    end

    it 'updates activity log tracker events when a protocol is created' do
      p = create_item name: "Test tracker events #{Time.now.to_f}"
      expect(p.sub_processes.pluck(:name)).to include('Activity')
    end
  end
  describe '#copy_from' do
    def get_clean_protocol(protocol)
      protocol = protocol ? Classification::Protocol.find(protocol.id) : create_item
      protocol.current_admin = @admin
      protocol
    end

    def check_protocols_match(source, target)
      # Check sub_processes were copied
      expect(target_protocol.sub_processes.enabled.count).not_to eq(0)
      expect(target_protocol.sub_processes.enabled.reload.count).to eq(source_protocol.sub_processes.enabled.reload.count)

      # Check each sub_process and its events
      target_protocol.sub_processes.enabled.reload.each_with_index do |sub, i|
        source_sub = source_protocol.sub_processes.reload.find_by(name: sub.name)

        # Check sub_process attributes
        expect(sub.name).to eq(source_sub.name)
        expect(sub.disabled).to eq(source_sub.disabled)

        # Check protocol_events
        expect(sub.protocol_events.enabled.reload.count).not_to eq(0)
        sub.protocol_events.enabled.reload.each_with_index do |event, j|
          source_event = source_sub.protocol_events.enabled.reload.find_by(name: event.name)

          expect(event.name).to eq(source_event.name)
          expect(event.disabled).to eq(source_event.disabled)
          expect(event.description).to eq(source_event.description)
          expect(event.milestone).to eq(source_event.milestone)
        end
      end
    end

    let(:source_protocol) { @source_protocol = get_clean_protocol(@source_protocol) }
    let(:target_protocol) { @target_protocol = get_clean_protocol(@target_protocol) }

    def add_protocols_and_sub_processes(state)
      2.times do |i|
        sub_process = source_protocol.sub_processes.create!(
          name: "Sub Process #{state} #{i}",
          current_admin: @admin,
          disabled: false
        )

        2.times do |j|
          sub_process.protocol_events.create!(
            name: "Event #{i}-#{j}",
            # position: j,
            disabled: false,
            # event_type: 'test_type',
            # options: { key: "value-#{i}-#{j}" },
            current_admin: @admin
          )
        end
      end
    end

    before do
      create_admin
      # Create sub_processes with events for source protocol
      add_protocols_and_sub_processes 'init'
    end

    it 'copies all sub_processes and protocol_events' do
      source_protocol.sub_processes.reload
      target_protocol.sub_processes.reload
      res = target_protocol.copy_from(source_protocol)
      # puts res.to_yaml
      expect(res.length).to eq 2
      expect(res).to eq(
        'Sub Process init 1' => ['Event 1-0', 'Event 1-1'],
        'Sub Process init 0' => ['Event 0-0', 'Event 0-1']
      )
      check_protocols_match(source_protocol, target_protocol)
    end

    it 'updates sub_processes and protocol_events if new ones are added in the source protocol' do
      source_protocol.sub_processes.reload
      target_protocol.sub_processes.reload
      res = target_protocol.copy_from(source_protocol)
      expect(res.length).to eq 2
      # puts res.to_yaml
      check_protocols_match(source_protocol, target_protocol)

      add_protocols_and_sub_processes 'update'
      source_protocol.sub_processes.reload
      target_protocol.sub_processes.reload

      res = target_protocol.copy_from(source_protocol)
      expect(res.length).to eq 2
      # puts res.to_yaml
      check_protocols_match(source_protocol, target_protocol)

      # Nothing new should be added if no changes in source
      res = target_protocol.copy_from(source_protocol)
      expect(res).to be_empty
      # puts res.to_yaml
      check_protocols_match(source_protocol, target_protocol)
    end

    it 'raises exception when copying from same protocol' do
      expect { target_protocol.copy_from(target_protocol) }.to raise_error(FphsException, "Can't copy protocol sub processes to self")
    end

    it 'maintains data consistency in transaction' do
      prev_count = target_protocol.sub_processes.reload.count
      allow(target_protocol.sub_processes).to receive(:create!).and_raise('Test error')

      expect do
        target_protocol.copy_from(source_protocol)
      end.to raise_error('Test error')

      # Verify no partial data was created
      expect(target_protocol.sub_processes.reload.count).to eq(prev_count)
    end
  end
end
