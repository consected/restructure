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

  #
  # Helper to reconfigure the activity log definition with a new extra_log_types YAML,
  # set up access, and return the definition for integration tests.
  # @param [String] extra_log_type_name - the extra log type name (e.g. 'case_test')
  # @param [String] yaml_config - the YAML configuration string
  def configure_al_with_save_trigger(extra_log_type_name, yaml_config)
    al_def = ActivityLog.find_by(id: ActivityLog::PlayerContactPhone.definition.id)

    al_def.extra_log_types = yaml_config
    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    setup_access :"activity_log__player_contact_phone__#{extra_log_type_name}",
                 resource_type: :activity_log_type, access: :create, user: @user

    al_def.add_master_association
    al_def
  end

  #
  # Helper to create an activity log record for integration tests.
  # @param [String] extra_log_type - the extra log type
  # @param [String] direction - the select_call_direction value
  # @param [String] who - the select_who value
  # @return [ActivityLog::PlayerContactPhone] the created activity log record
  def create_al_record(extra_log_type:, direction: 'to player', who: 'original')
    @master.activity_log__player_contact_phones.create!(
      select_call_direction: direction,
      select_who: who,
      extra_log_type:,
      player_contact: @player_contact,
      master: @master,
      current_user: @user
    )
  end

  #
  # Build a when/then branch for a case config.
  # @param [Symbol] field - the field to match against
  # @param [String] value - the expected value
  # @param [Array<Hash>] triggers - trigger configs to execute on match
  # @return [Hash] a when/then branch hash
  def when_branch(field, value, triggers)
    {
      when: { all: { this: { field => value } } },
      then: triggers
    }
  end

  #
  # Build an else branch for a case config.
  # @param [Array<Hash>] triggers - trigger configs to execute
  # @return [Hash] an else branch hash
  def else_branch(triggers)
    { else: triggers }
  end

  #
  # Build a log trigger config.
  # @param [String] message - the log message
  # @param [String] severity - log severity level (default: 'info')
  # @return [Hash] a log trigger config
  def log_trigger(message, severity: 'info')
    { log: { message:, severity: } }
  end

  describe '#perform' do
    context 'when a when condition matches' do
      it 'executes the then triggers for the first matching when block - Issue #944' do
        config = [
          when_branch(:select_call_direction, 'to player', [log_trigger('Matched to player')])
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/Matched to player/).ordered
        expect(Rails.logger).to receive(:info).with(/SaveTrigger::Case/).ordered

        result = trigger.perform

        expect(result).to be_present
      end

      it 'executes multiple triggers in the then block - Issue #944' do
        config = [
          when_branch(:select_call_direction, 'to player', [
                        log_trigger('First then trigger'),
                        log_trigger('Second then trigger', severity: 'debug')
                      ])
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        result = trigger.perform

        expect(result.length).to eq(2)
        expect(result[0][:trigger]).to eq(:log)
        expect(result[1][:trigger]).to eq(:log)
      end
    end

    context 'when multiple when conditions could match' do
      it 'executes only the first matching when block - Issue #944' do
        config = [
          when_branch(:select_call_direction, 'to player', [log_trigger('First match')]),
          when_branch(:select_who, 'user', [log_trigger('Second match should not run')])
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        result = trigger.perform

        expect(result.length).to eq(1)
        expect(result.first[:trigger]).to eq(:log)
      end
    end

    context 'when the first when does not match but the second does' do
      it 'skips the first and executes the second when block - Issue #944' do
        config = [
          when_branch(:select_call_direction, 'from player', [log_trigger('First branch - should not run')]),
          when_branch(:select_who, 'user', [log_trigger('Second branch matched')])
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
          when_branch(:select_call_direction, 'from player', [log_trigger('Should not match')]),
          else_branch([log_trigger('Fell through to else')])
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        result = trigger.perform

        expect(result.length).to eq(1)
        expect(result.first[:trigger]).to eq(:log)
      end

      it 'does not execute else when a when condition matched - Issue #944' do
        config = [
          when_branch(:select_call_direction, 'to player', [log_trigger('Matched branch')]),
          else_branch([log_trigger('Should not reach else')])
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        result = trigger.perform

        # Only one trigger result from the matched when, not from else
        expect(result.length).to eq(1)
      end
    end

    context 'when no when condition matches and no else is present' do
      it 'returns empty results - Issue #944' do
        config = [
          when_branch(:select_call_direction, 'from player', [log_trigger('Should not run')])
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        result = trigger.perform

        expect(result).to eq([])
      end
    end

    context 'with empty config' do
      it 'handles empty array gracefully - Issue #944' do
        trigger = SaveTriggers::Case.new([], @activity_log)
        result = trigger.perform

        expect(result).to eq([])
      end
    end

    context 'storing results' do
      it 'stores results in save_trigger_results - Issue #944' do
        config = [
          when_branch(:select_call_direction, 'to player', [log_trigger('Stored result test')])
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        trigger.perform

        expect(@activity_log.save_trigger_results['case']).to be_an(Array)
        expect(@activity_log.save_trigger_results['case'].length).to eq(1)
        expect(@activity_log.save_trigger_results['case'].first[:trigger]).to eq(:log)
      end

      it 'stores empty results when no branch matched - Issue #944' do
        config = [
          when_branch(:select_call_direction, 'from player', [log_trigger('Will not match')])
        ]

        trigger = SaveTriggers::Case.new(config, @activity_log)
        trigger.perform

        expect(@activity_log.save_trigger_results['case']).to eq([])
      end
    end
  end

  describe 'integration with save_trigger config' do
    it 'runs case trigger as part of on_create save_trigger - Issue #944' do
      configure_al_with_save_trigger('case_test', <<~END_DEF)
        case_test:
          label: Case Test
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              case:
                - when:
                    all:
                      this:
                        select_call_direction: 'to player'
                  then:
                    - update_this:
                        one:
                          with:
                            select_who: 'matched to player'
                - when:
                    all:
                      this:
                        select_call_direction: 'from player'
                  then:
                    - update_this:
                        one:
                          with:
                            select_who: 'matched from player'
                - else:
                    - update_this:
                        one:
                          with:
                            select_who: 'no match - else'
      END_DEF

      al = create_al_record(extra_log_type: 'case_test', direction: 'to player')
      expect(al.select_who).to eq 'matched to player'
    end

    it 'runs else branch when no when matches in save_trigger - Issue #944' do
      configure_al_with_save_trigger('case_else_test', <<~END_DEF)
        case_else_test:
          label: Case Else Test
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              case:
                - when:
                    all:
                      this:
                        select_call_direction: 'something else'
                  then:
                    - update_this:
                        one:
                          with:
                            select_who: 'should not match'
                - else:
                    - update_this:
                        one:
                          with:
                            select_who: 'fell through to else'
      END_DEF

      al = create_al_record(extra_log_type: 'case_else_test', direction: 'to player')
      expect(al.select_who).to eq 'fell through to else'
    end

    it 'runs second when branch in save_trigger - Issue #944' do
      configure_al_with_save_trigger('case_second_test', <<~END_DEF)
        case_second_test:
          label: Case Second Test
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              case:
                - when:
                    all:
                      this:
                        select_call_direction: 'something else'
                  then:
                    - update_this:
                        one:
                          with:
                            select_who: 'first branch'
                - when:
                    all:
                      this:
                        select_call_direction: 'from player'
                  then:
                    - update_this:
                        one:
                          with:
                            select_who: 'second branch matched'
      END_DEF

      al = create_al_record(extra_log_type: 'case_second_test', direction: 'from player')
      expect(al.select_who).to eq 'second branch matched'
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
