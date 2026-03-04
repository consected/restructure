# frozen_string_literal: true

# Tests for SaveTriggers::Case - Issue #944
# Implements a case/when/else save trigger block that evaluates conditions
# and executes the triggers associated with the first matching condition,
# or an else block if no conditions match.
# This is similar to the transaction save trigger block but adds
# conditional branching logic.

require 'rails_helper'

RSpec.describe SaveTriggers::Case, type: :model do
  include ModelSupport
  include PlayerContactSupport

  before :each do
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    @master = @player_contact.master
    expect(@master).not_to be nil

    # Set up activity log definition with save_trigger_results support
    al_def = ActivityLog.find_by(id: ActivityLog::PlayerContactPhone.definition.id)
    unless al_def
      SetupHelper.setup_al_gen_tests('Phone Log', nil, 'player_contact', rec_type: 'phone')
      al_def = ActivityLog.active.where(item_type: 'player_contact', rec_type: 'phone').first
    end

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    al_def.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1
        fields:
          - select_call_direction
          - select_who
    END_DEF

    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, access: :create,
                                                              user: @user
    al_def.add_master_association

    @activity_log = @master.activity_log__player_contact_phones.create!(
      select_call_direction: 'to player',
      select_who: 'user',
      extra_log_type: 'step_1',
      player_contact: @player_contact,
      master: @master,
      current_user: @user
    )
    @activity_log.save_trigger_results ||= {}
  end

  describe '#perform' do
    context 'when a when condition matches' do
      it 'executes the then triggers for the first matching when block - Issue #944' do
        config = [
          {
            when: {
              all: {
                this: {
                  select_call_direction: 'to player'
                }
              }
            },
            then: [
              { log: { message: 'Matched to player', severity: 'info' } }
            ]
          }
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/Matched to player/).ordered
        expect(Rails.logger).to receive(:info).with(/SaveTrigger::Case/).ordered

        result = trigger.perform

        expect(result).to be_present
      end
    end

    context 'when multiple when conditions could match' do
      it 'executes only the first matching when block - Issue #944' do
        config = [
          {
            when: {
              all: {
                this: {
                  select_call_direction: 'to player'
                }
              }
            },
            then: [
              { log: { message: 'First match', severity: 'info' } }
            ]
          },
          {
            when: {
              all: {
                this: {
                  select_who: 'user'
                }
              }
            },
            then: [
              { log: { message: 'Second match should not run', severity: 'info' } }
            ]
          }
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        result = trigger.perform

        expect(result.length).to eq(1)
        expect(result.first[:trigger]).to eq(:log)
      end
    end

    context 'when no when condition matches and else is present' do
      it 'executes the else triggers - Issue #944' do
        config = [
          {
            when: {
              all: {
                this: {
                  select_call_direction: 'from player'
                }
              }
            },
            then: [
              { log: { message: 'Should not match', severity: 'info' } }
            ]
          },
          {
            else: [
              { log: { message: 'Fell through to else', severity: 'info' } }
            ]
          }
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        result = trigger.perform

        expect(result.length).to eq(1)
        expect(result.first[:trigger]).to eq(:log)
      end
    end

    context 'when no when condition matches and no else is present' do
      it 'returns empty results - Issue #944' do
        config = [
          {
            when: {
              all: {
                this: {
                  select_call_direction: 'from player'
                }
              }
            },
            then: [
              { log: { message: 'Should not run', severity: 'info' } }
            ]
          }
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        result = trigger.perform

        expect(result).to eq([])
      end
    end

    context 'storing results' do
      it 'stores results in save_trigger_results - Issue #944' do
        config = [
          {
            when: {
              all: {
                this: {
                  select_call_direction: 'to player'
                }
              }
            },
            then: [
              { log: { message: 'Stored result test', severity: 'info' } }
            ]
          }
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        trigger.perform

        expect(@activity_log.save_trigger_results['case']).to be_an(Array)
        expect(@activity_log.save_trigger_results['case'].length).to eq(1)
        expect(@activity_log.save_trigger_results['case'].first[:trigger]).to eq(:log)
      end
    end
  end

  describe 'registration' do
    it 'is included in ValidSaveTriggers - Issue #944' do
      expect(OptionConfigs::ExtraOptionImplementers::SaveTriggers::ValidSaveTriggers).to include(:case)
    end

    it 'can be resolved via trigger_class - Issue #944' do
      klass = OptionConfigs::ExtraOptions.trigger_class(:case)
      expect(klass).to eq(SaveTriggers::Case)
    end
  end
end
