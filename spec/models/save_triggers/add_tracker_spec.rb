require 'rails_helper'

AlNameGenTestAt = 'Gen Test ELT 2'

RSpec.describe SaveTriggers::AddTracker, type: :model do
  include ModelSupport
  include ActivityLogSupport

  before :example do
    SetupHelper.setup_al_player_contact_phones
    SetupHelper.setup_al_gen_tests AlNameGenTestAt, 'elt2_test', 'player_contact'
    ud, = create_user
    ud.disable!
    u0, = create_user
    u1, = create_user
    create_user
    let_user_create :player_contacts
    ActivityLog::PlayerContactPhone.definition.update_tracker_events
    ActivityLog::PlayerContactElt2Test.definition.update_tracker_events

    @master0 = create_master
    @player_contact = @master0.player_contacts.create! data: '(617)123-1234', rec_type: :phone, rank: 10
    @al0 = create_item master: @master0
    @master = create_master
    @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
    @al = create_item master: @master

    expect(@al0.master_id).to eq @master0.id
    expect(@al.master_id).to eq @master.id
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
  end

  it 'generates a tracker entry' do
    sp_name = 'REDCap'
    pe_name = 'bounced email'
    text = "This is a test.\nIt works!"

    sp1_name = 'Alerts'
    pe1_name = 'Level 1'
    text1 = 'Another test with {{master_id}}'

    config = {
      Q1: {
        with: {
          # master_id: alternative master_id based on value or reference definition
          sub_process_name: sp_name,
          protocol_event_name: pe_name,
          notes: text
          # item_type: model_name,
          # item_id: model_id
        }
      },
      Study: {
        with: {
          sub_process_name: sp1_name,
          protocol_event_name: pe1_name,
          notes: text1,
          event_date: '-3 days'
        }
      },
      General: {
        if: { # will fail to evaluate true
          all: {
            this: {
              master_id: -999
            }
          }
        },
        with: {
          sub_process_name: sp1_name,
          protocol_event_name: pe1_name,
          notes: text1,
          event_date: '-3 days'
        }
      }
    }

    @trigger = SaveTriggers::AddTracker.new(config, @al)

    @trigger.perform

    expect(@trigger.trackers).to be_a Array
    expect(@trigger.trackers).not_to be_empty
    expect(@trigger.trackers.map(&:keys).flatten).to eq %i[Q1 Study General]

    tracker = @trigger.trackers.first[:Q1]

    expect(tracker).to be_a Tracker
    expect(tracker.protocol.name).to eq 'Q1'
    expect(tracker.sub_process.name).to eq sp_name
    expect(tracker.protocol_event.name).to eq pe_name
    expect(tracker.notes).to eq text
    expect(tracker.event_date).not_to be_nil
    expect(tracker.item).to eq @al
    expect(tracker.master_id).to eq @master.id

    tracker = @trigger.trackers[1][:Study]

    expect(tracker).to be_a Tracker
    expect(tracker.protocol.name).to eq 'Study'
    expect(tracker.sub_process.name).to eq sp1_name
    expect(tracker.protocol_event.name).to eq pe1_name
    expect(tracker.notes).to eq text1.gsub('{{master_id}}', @al.master_id.to_s)
    expect(tracker.event_date).to eq (Date.today - 3.days).strftime('%Y-%m-%d')
    expect(tracker.item).to eq @al
    expect(tracker.master_id).to eq @master.id

    tracker = @trigger.trackers[2][:General]
    expect(tracker).to be_nil
  end

  it 'generates a tracker entry with different item and master' do
    sp_name = 'REDCap'
    pe_name = 'bounced email'
    text = "This is a test.\nIt works!"

    study_p = Classification::Protocol.find_by_name('Study')
    sp1_name = 'Alerts'
    pe1_name = 'Level 1'
    text1 = 'Another test with {{master_id}}'

    text2 = 'Different text'

    config = [
      {
        Q1: {
          if: {
            never: true
          },
          with: {
            sub_process_name: sp_name,
            protocol_event_name: pe_name,
            notes: text
          }
        }
      },
      {
        Study: {
          with: {
            sub_process_name: sp1_name,
            protocol_event_name: pe1_name,
            notes: text1,
            event_date: '-3 days'
          }
        }
      },
      {
        Q1: {
          if: {
            always: true
          },
          with: {
            sub_process_name: sp_name,
            protocol_event_name: pe_name,
            notes: text2,
            master_id: @master0.id,
            item_id: @al0.id,
            item_type: @al0.class.name
          }
        }
      },
      {
        dynamic: {
          with: {
            protocol_name: 'Study',
            sub_process_name: sp1_name,
            protocol_event_name: pe1_name
          }
        }
      },
      {
        dynamic2: {
          with: {
            protocol_id: study_p.id,
            sub_process_name: sp1_name,
            protocol_event_name: pe1_name
          }
        }
      }

    ]

    @trigger = SaveTriggers::AddTracker.new(config, @al)
    @trigger.perform

    expect(@trigger.trackers).to be_a Array
    expect(@trigger.trackers).not_to be_empty
    expect(@trigger.trackers.map(&:keys).flatten).to eq %i[Q1 Study Q1 dynamic dynamic2]

    tracker = @trigger.trackers.first[:Q1]

    expect(tracker).to be nil

    tracker = @trigger.trackers[1][:Study]

    expect(tracker).to be_a Tracker
    expect(tracker.protocol.name).to eq 'Study'
    expect(tracker.sub_process.name).to eq sp1_name
    expect(tracker.protocol_event.name).to eq pe1_name
    expect(tracker.notes).to eq text1.gsub('{{master_id}}', @al.master_id.to_s)
    expect(tracker.event_date).to eq (Date.today - 3.days).strftime('%Y-%m-%d')
    expect(tracker.item).to eq @al
    expect(tracker.master_id).to eq @master.id

    tracker = @trigger.trackers[2][:Q1]

    expect(tracker).to be_a Tracker
    expect(tracker.protocol.name).to eq 'Q1'
    expect(tracker.sub_process.name).to eq sp_name
    expect(tracker.protocol_event.name).to eq pe_name
    expect(tracker.notes).to eq text2
    expect(tracker.event_date).not_to be_nil
    expect(tracker.item.id).to eq @al0.id
    expect(tracker.master_id).to eq @master0.id

    # Use the {with: {protocol_name: ...}} configuration instead of the {dynamic: } key
    tracker = @trigger.trackers[3][:dynamic]

    expect(tracker).to be_a Tracker
    expect(tracker.protocol.name).to eq 'Study'
    expect(tracker.sub_process.name).to eq sp1_name
    expect(tracker.protocol_event.name).to eq pe1_name
    expect(tracker.master_id).to eq @master.id

    # Use the {with: {protocol_id: ...}} configuration instead of the {dynamic2: } key
    tracker = @trigger.trackers[4][:dynamic2]

    expect(tracker).to be_a Tracker
    expect(tracker.protocol.id).to eq study_p.id
    expect(tracker.sub_process.name).to eq sp1_name
    expect(tracker.protocol_event.name).to eq pe1_name
    expect(tracker.master_id).to eq @master.id
  end

  it 'add tracker on save_trigger in an activity log' do
    # Setup a new activity log with add trackers on create

    @activity_log = al = ActivityLog.active.where(name: AlNameGenTestAt).first

    raise "Activity Log #{AlNameGenTestAt} not set up" if al.nil?

    sp1_name = 'Alerts'
    pe1_name = 'Level 1'
    text1 = 'Another test with {{master_id}}'

    al.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1
        fields:
          - select_call_direction
          - select_who
        save_trigger:
          on_create:
            add_tracker:
              - Study:
                  with:
                    sub_process_name: #{sp1_name}
                    protocol_event_name: #{pe1_name}
                    notes: #{text1}
                    event_date: '-5 days'
              - Q1:
                  with:
                    sub_process_name: non-existent
                    protocol_event_name: non-existent
                  if:
                    never: true

      step_2:
        label: Step 2
        fields:
          - select_call_direction
          - extra_text

    END_DEF

    al.current_admin = @admin
    al.save!

    user = @user
    @player_contact.current_user = user

    setup_access al.resource_name, resource_type: :table, access: :create, user: user

    alstep1 = @player_contact.activity_log__player_contact_elt2_tests.build(select_call_direction: 'from player', select_who: 'user', extra_log_type: 'step_1')

    setup_access alstep1.resource_name, resource_type: :activity_log_type, access: :create, user: user

    alstep1.save!
    expect(alstep1).to be_persisted

    alstep2 = @player_contact.activity_log__player_contact_elt2_tests.build(select_call_direction: 'from staff', select_who: 'user', extra_log_type: 'step_1')
    alstep2.save!

    tracker = TrackerHistory.reorder('').last
    expect(tracker)

    expect(tracker).to be_a TrackerHistory
    expect(tracker.protocol.name).to eq 'Study'
    expect(tracker.sub_process.name).to eq sp1_name
    expect(tracker.protocol_event.name).to eq pe1_name
    expect(tracker.notes).to eq text1.gsub('{{master_id}}', alstep2.master_id.to_s)
    expect(tracker.event_date).to eq (Date.today - 5.days).strftime('%Y-%m-%d')
    expect(tracker.item).to eq alstep2
    expect(tracker.master_id).to eq alstep2.master.id
  end
end
