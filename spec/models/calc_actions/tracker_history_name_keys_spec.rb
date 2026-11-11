# frozen_string_literal: true

# Specs for GitHub Issue #1491 (Option 1): protocol_name, sub_process_name and protocol_event_name keys in
# tracker_history conditions. Each name is resolved within its parent, so the same sub process and event names can be
# used under different protocols without ambiguity. Values are evaluated with dynamic_value, so substitutions may be
# used. Names that cannot be resolved, or that are supplied without a parent or alongside an id, raise a FphsException.
require 'rails_helper'

RSpec.describe 'tracker_history name keys in conditional calculations', type: :model do
  include ModelSupport

  def calc(conf, instance = @tracker)
    ConditionalActions.new(conf, instance).calc_action_if
  end

  before :each do
    create_user
    create_admin
    setup_access :trackers
    setup_access :tracker_histories

    # P1 and P2 both have a sub process named 'Information' with an event named 'Error'
    @protocol = Classification::Protocol.create name: 'P1', current_admin: @admin
    @sub_process = @protocol.sub_processes.create name: 'Information', current_admin: @admin
    @event = @sub_process.protocol_events.create name: 'Error', current_admin: @admin

    @other_protocol = Classification::Protocol.create name: 'P2', current_admin: @admin
    @other_sub_process = @other_protocol.sub_processes.create name: 'Information', current_admin: @admin
    @other_event = @other_sub_process.protocol_events.create name: 'Error', current_admin: @admin

    @master = Master.new
    @master.current_user = @user
    @master.save!

    @tracker = @master.trackers.create protocol_id: @protocol.id, sub_process_id: @sub_process.id,
                                       protocol_event_id: @event.id, event_date: DateTime.now
  end

  describe 'resolving names to ids' do
    it 'matches the tracker_history record when all three names identify it' do
      conf = { all: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Information',
                                         protocol_event_name: 'Error' } } }
      expect(calc(conf)).to be true
    end

    it 'does not match when the names identify a different protocol that reuses the sub process and event names' do
      conf = { all: { tracker_history: { protocol_name: 'P2', sub_process_name: 'Information',
                                         protocol_event_name: 'Error' } } }
      expect(calc(conf)).to be false
    end

    it 'resolves the sub process within the named protocol, not the first sub process with that name' do
      conf = { all: { tracker_history: { protocol_name: 'P2', sub_process_name: 'Information' } } }
      expect(calc(conf)).to be false

      conf[:all][:tracker_history][:protocol_name] = 'P1'
      expect(calc(conf)).to be true
    end

    it 'returns false for a valid event name that the tracker_history record does not use' do
      @sub_process.protocol_events.create name: 'Other', current_admin: @admin
      conf = { all: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Information',
                                         protocol_event_name: 'Other' } } }
      expect(calc(conf)).to be false
    end

    it 'accepts a protocol_id parent with a sub_process_name and protocol_event_name' do
      conf = { all: { tracker_history: { protocol_id: @protocol.id, sub_process_name: 'Information',
                                         protocol_event_name: 'Error' } } }
      expect(calc(conf)).to be true
    end

    it 'accepts a sub_process_id parent with a protocol_event_name' do
      conf = { all: { tracker_history: { sub_process_id: @sub_process.id, protocol_event_name: 'Error' } } }
      expect(calc(conf)).to be true
    end

    it 'allows id keys and name keys to be mixed at different levels' do
      conf = { all: { tracker_history: { protocol_name: 'P1', sub_process_id: @sub_process.id,
                                         protocol_event_id: @event.id } } }
      expect(calc(conf)).to be true
    end
  end

  describe 'substitutions' do
    it 'evaluates a substitution for each name key' do
      conf = { all: { tracker_history: { protocol_name: '{{protocol.name}}',
                                         sub_process_name: '{{sub_process.name}}',
                                         protocol_event_name: '{{protocol_event.name}}' } } }
      expect(calc(conf)).to be true
    end

    it 'raises when a substituted name does not match an active record' do
      conf = { all: { tracker_history: { protocol_name: '{{sub_process.name}}' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_name 'Information'/)
    end
  end

  describe 'unresolved and incomplete names' do
    it 'raises for an unknown protocol name' do
      conf = { all: { tracker_history: { protocol_name: 'Nope' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_name 'Nope'/)
    end

    it 'raises for an unknown protocol name under not_all, rather than always passing' do
      conf = { not_all: { tracker_history: { protocol_name: 'Nope' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_name 'Nope'/)
    end

    it 'raises for an unknown sub process name within the protocol' do
      conf = { all: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Missing' } } }
      expect { calc(conf) }.to raise_error(FphsException, /sub_process_name 'Missing'/)
    end

    it 'raises for a sub process that exists only under a different protocol' do
      @other_sub_process.update!(name: 'Elsewhere', current_admin: @admin)
      conf = { all: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Elsewhere' } } }
      expect { calc(conf) }.to raise_error(FphsException, /sub_process_name 'Elsewhere'/)
    end

    it 'raises for an unknown protocol event name within the sub process' do
      conf = { all: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Information',
                                         protocol_event_name: 'Missing' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_event_name 'Missing'/)
    end

    it 'raises for a disabled protocol, which is not an active record' do
      @protocol.update!(disabled: true, current_admin: @admin)
      conf = { all: { tracker_history: { protocol_name: 'P1' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_name 'P1'/)
    end

    it 'raises for a blank name' do
      conf = { all: { tracker_history: { protocol_name: '' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_name must not be blank/)
    end

    it 'raises for a sub_process_name without a protocol_id or protocol_name' do
      conf = { all: { tracker_history: { sub_process_name: 'Information' } } }
      expect { calc(conf) }.to raise_error(FphsException, /sub_process_name.*protocol_id or protocol_name/)
    end

    it 'raises for a protocol_event_name without a sub_process_id or sub_process_name' do
      conf = { all: { tracker_history: { protocol_name: 'P1', protocol_event_name: 'Error' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_event_name.*sub_process_id or sub_process_name/)
    end

    it 'raises when a protocol_event_name is given with only a protocol_id' do
      conf = { all: { tracker_history: { protocol_id: @protocol.id, protocol_event_name: 'Error' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_event_name.*sub_process_id or sub_process_name/)
    end
  end

  describe 'id and name at the same level' do
    it 'raises when protocol_id and protocol_name are both given' do
      conf = { all: { tracker_history: { protocol_id: @protocol.id, protocol_name: 'P1' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_id and protocol_name/)
    end

    it 'raises when sub_process_id and sub_process_name are both given' do
      conf = { all: { tracker_history: { protocol_name: 'P1', sub_process_id: @sub_process.id,
                                         sub_process_name: 'Information' } } }
      expect { calc(conf) }.to raise_error(FphsException, /sub_process_id and sub_process_name/)
    end

    it 'raises when protocol_event_id and protocol_event_name are both given' do
      conf = { all: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Information',
                                         protocol_event_id: @event.id, protocol_event_name: 'Error' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_event_id and protocol_event_name/)
    end
  end

  describe 'with other selection types' do
    it 'applies the names within not_all, which is false when the record matches' do
      conf = { not_all: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Information',
                                             protocol_event_name: 'Error' } } }
      expect(calc(conf)).to be false
    end

    it 'applies the names within not_all, which is true when only a different protocol matches' do
      conf = { not_all: { tracker_history: { protocol_name: 'P2', sub_process_name: 'Information',
                                             protocol_event_name: 'Error' } } }
      expect(calc(conf)).to be true
    end

    it 'applies the names within any' do
      conf = { any: { tracker_history: { protocol_name: 'P2', sub_process_name: 'Information' } } }
      expect(calc(conf)).to be false

      conf = { any: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Information' } } }
      expect(calc(conf)).to be true
    end

    it 'applies the names within not_any' do
      conf = { not_any: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Information' } } }
      expect(calc(conf)).to be false

      conf = { not_any: { tracker_history: { protocol_name: 'P2', sub_process_name: 'Information' } } }
      expect(calc(conf)).to be true
    end

    it 'applies the names within a nested all block' do
      conf = { any: { all: { tracker_history: { protocol_name: 'P1', sub_process_name: 'Information' } } } }
      expect(calc(conf)).to be true
    end
  end

  describe 'with no_masters' do
    it 'matches the tracker_history records without joining to masters' do
      conf = { all: { no_masters: {}, tracker_history: { protocol_name: 'P1', sub_process_name: 'Information',
                                                         protocol_event_name: 'Error' } } }
      expect(calc(conf)).to be true
    end

    it 'does not match a protocol that reuses the sub process and event names' do
      conf = { all: { no_masters: {}, tracker_history: { protocol_name: 'P2', sub_process_name: 'Information',
                                                         protocol_event_name: 'Error' } } }
      expect(calc(conf)).to be false
    end

    it 'raises for an unknown name' do
      conf = { all: { no_masters: {}, tracker_history: { protocol_name: 'Nope' } } }
      expect { calc(conf) }.to raise_error(FphsException, /protocol_name 'Nope'/)
    end
  end
end
