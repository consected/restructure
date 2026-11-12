# frozen_string_literal: true

# Purpose: verify Dynamic::TemplateConfigFreshness, which works out which records and live
# definitions the template_config (and index / show) freshness depends on.
#
# These specs verify that:
# - #records returns one sorted representative root per definition version, plus embedded
#   items and model-referenced records, without duplicates
# - .refresh_live_definitions and #refresh! refresh each distinct live definition once,
#   including the definitions of model reference target classes
# - #tokens changes after a config-only definition edit, an edit to a YAML config library
#   used by the definition, and (for activity logs) an edit to a sibling definition sharing
#   the same item_type
require 'rails_helper'

RSpec.describe Dynamic::TemplateConfigFreshness, type: :model do
  include ModelSupport

  fake_fields = %i[id updated_at vdef_version option_type extra_log_type def_version item_type
                   current_definition embedded_item model_references]

  before do
    stub_const('FreshnessFakeA', Struct.new(*fake_fields, keyword_init: true))
    stub_const('FreshnessFakeB', Struct.new(*fake_fields, keyword_init: true))
  end

  def fake(klass = FreshnessFakeA, **attrs)
    klass.new(updated_at: Time.zone.at(1_700_000_000), model_references: [], **attrs)
  end

  describe '#records' do
    it 'returns one root per definition version, sorted by class name and id' do
      roots = [
        fake(FreshnessFakeB, id: 3, option_type: 'x', def_version: 1),
        fake(FreshnessFakeB, id: 4, option_type: 'x', def_version: 1),
        fake(FreshnessFakeB, id: 5, option_type: 'x', def_version: 2),
        fake(FreshnessFakeA, id: 9, extra_log_type: 'step')
      ]

      records = described_class.new(roots).records

      expect(records).to eq [roots[3], roots[0], roots[2]]
    end

    it 'adds embedded items and referenced records once, ignoring blank roots' do
      embedded = fake(FreshnessFakeB, id: 20)
      referenced = fake(FreshnessFakeB, id: 21)
      root = fake(FreshnessFakeA, id: 1, option_type: 'x', embedded_item: embedded)
      other_root = fake(FreshnessFakeA, id: 2, option_type: 'y', embedded_item: embedded)
      root.model_references = [double(to_record: referenced), double(to_record: nil)]

      records = described_class.new([root, nil, other_root]).records

      expect(records).to eq [root, other_root, embedded, referenced]
    end
  end

  describe 'refreshing live definitions' do
    def definition(id)
      instance_double(DynamicModel, id:, refresh_current_def_version!: nil)
    end

    it 'refreshes each distinct live definition once per call' do
      shared = definition(1)
      other = definition(2)
      records = [
        fake(id: 1, option_type: 'x', current_definition: shared),
        fake(id: 2, option_type: 'y', current_definition: shared),
        fake(id: 3, option_type: 'z', current_definition: other)
      ]

      described_class.refresh_live_definitions(records)

      expect(shared).to have_received(:refresh_current_def_version!).once
      expect(other).to have_received(:refresh_current_def_version!).once
    end

    it 'only walks model references of one representative record per type' do
      records = [fake(id: 1, option_type: 'x'), fake(id: 2, option_type: 'x')]
      expect(records.first).to receive(:model_references).once.and_return([])
      expect(records.second).not_to receive(:model_references)

      described_class.refresh_live_definitions(records)
    end

    it 'also refreshes the definitions of model reference target classes' do
      target_definition = definition(7)
      target_class = double('ReferenceTargetClass', definition: target_definition)
      allow(ModelReference).to receive(:to_record_class_for_type).with('target_type').and_return(target_class)
      root = fake(id: 1, option_type: 'x', model_references: [double(to_record_type: 'target_type')])

      described_class.refresh_live_definitions([root])

      expect(target_definition).to have_received(:refresh_current_def_version!).once
    end

    it 'refreshes definitions of embedded and referenced records through #refresh!' do
      root_definition = definition(1)
      embedded_definition = definition(2)
      embedded = fake(FreshnessFakeB, id: 20, option_type: 'e', current_definition: embedded_definition)
      root = fake(id: 1, option_type: 'x', current_definition: root_definition, embedded_item: embedded)

      described_class.new([root]).refresh!

      expect(root_definition).to have_received(:refresh_current_def_version!).once
      expect(embedded_definition).to have_received(:refresh_current_def_version!).once
    end
  end

  describe '#tokens' do
    before :all do
      change_setting('AllowDynamicMigrations', true)
      create_admin

      @rand_id = SecureRandom.hex(4)
      @category = "tcfcat#{@rand_id}"
      @library = Admin::ConfigLibrary.create!(
        current_admin: @admin, name: "tcflib#{@rand_id}", category: @category,
        format: 'yaml', options: "_definitions_lib:\n  tcf_label: &tcf_label Original Label\n"
      )
      @dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test tcf #{@rand_id}",
        table_name: "test_tcf#{@rand_id}s",
        schema_name: 'dynamic_test',
        primary_key_name: :id,
        foreign_key_name: :master_id,
        category: :test,
        options: dm_options('One')
      )
      DynamicModel.refresh_outdated
    end

    after :all do
      @dm&.disable!(@admin)
      change_setting('AllowDynamicMigrations', false)
    end

    def dm_options(caption)
      <<~YAML
        # @library #{@category} #{@library.name}
        _configurations:
          use_current_version: true
        default:
          label: *tcf_label
          caption_before:
            test1: #{caption}
      YAML
    end

    def live_tokens(**)
      definition = DynamicModel.find(@dm.id)
      record = fake(id: 1, current_definition: definition, option_type: 'x')
      freshness = described_class.new([record])
      freshness.refresh!
      freshness.tokens(**)
    end

    it 'is stable when nothing has changed' do
      expect(live_tokens).to eq(live_tokens)
    end

    it 'changes after a config-only definition edit' do
      before_tokens = live_tokens

      definition = DynamicModel.find(@dm.id)
      definition.current_admin = @admin
      definition.update!(options: dm_options('Two'))

      expect(live_tokens).not_to eq(before_tokens)
    end

    it 'changes after an edit to a YAML library used by the definition' do
      before_tokens = live_tokens

      @library.current_admin = @admin
      @library.update!(options: "_definitions_lib:\n  tcf_label: &tcf_label Changed Label\n")
      @library.update_columns(updated_at: @library.updated_at + 2.seconds)

      expect(live_tokens).not_to eq(before_tokens)
    end

    it 'changes for an activity log item_type after a sibling definition edit' do
      sibling = ActivityLog.active.first!
      record = fake(id: 1, item_type: sibling.item_type)
      before_tokens = described_class.new([record]).tokens(include_activity_item_types: true)
      expect(described_class.new([record]).tokens).to eq(described_class.new([record]).tokens)

      sibling.current_admin = @admin
      original_name = sibling.main_log_name
      begin
        sibling.update!(main_log_name: "#{original_name} Edited")
        after_tokens = described_class.new([record]).tokens(include_activity_item_types: true)
      ensure
        sibling.reload.update!(main_log_name: original_name)
      end

      expect(after_tokens).not_to eq(before_tokens)
    end
  end
end
