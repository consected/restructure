# frozen_string_literal: true

require 'rails_helper'

# Coverage of Dynamic::DefinitionLoadIssues, which reports active dynamic definitions that could not be
# loaded, grouped by cause, and of how Admin::ServerInfo#configuration_failed_reason surfaces the result.
#
# It reads state that AppControl.define_models and the generators leave behind. The definitions are real,
# with the failure injected by the cheapest realistic means: a dropped table, options that raise on parse, a
# reference to a missing model, and (only for a class build exception) a narrow stub.
#
# Coverage:
# - table_or_view_not_found: an active definition (DynamicModel, ExternalIdentifier) with no generated class and
#   no table or view
# - failed_to_create: a class build exception (DynamicModel, ActivityLog, ExternalIdentifier), the ActivityLog
#   post-generation check failure, and the first line / truncation of the recorded message
# - options_parse_exception: options that raise on parse; options that parse with validation errors are not listed
# - unresolved_references: a reference to a missing model; a forward reference repaired by
#   resolve_cached_forward_references! is not listed
# - grouping: one line per non-empty category, in a fixed order, with the definition detail
# - each definition links to its admin edit page, and exception details are escaped
# - items disappear when regeneration or reparse succeeds, and when a definition is disabled
# - definitions sharing one implementation class are not reported
# - the gate: nothing before a define_models run completes, while one is in progress, or during an import
# - Admin::ServerInfo#configuration_failed_reason includes the lines, and a failure to build them does not
#   break it
RSpec.describe Dynamic::DefinitionLoadIssues, type: :model do
  include ModelSupport

  def bad_anchor_options
    <<~YAML
      default:
        label: Bad anchor
        show_if:
          some_field:
            this:
              other_field: &is_blank
    YAML
  end

  def good_options
    <<~YAML
      default:
        label: Good options
    YAML
  end

  def create_dynamic_model(suffix, options: nil)
    DynamicModel.create!(
      current_admin: @admin,
      name: "load issue #{suffix} #{@rand_id}",
      table_name: "loadissue#{suffix}#{@rand_id}s",
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options:
    )
  end

  # The name is kept short, since the history table's default index names (index_<schema>.<name>_history_on_admin_id)
  # must fit the 63 character Postgres limit
  def create_external_identifier(suffix)
    ExternalIdentifier.create!(
      current_admin: @admin,
      name: "li#{suffix}#{@rand_id}s",
      label: "Load issue #{suffix}",
      external_id_attribute: "li#{suffix}#{@rand_id}_ext_id",
      min_id: 1,
      max_id: 99_999_999,
      # Migrations are skipped for the default ml_app schema, so the table would never be created
      schema_name: 'dynamic_test',
      category: :test
    )
  end

  def drop_table_and_regenerate(definition)
    %W[#{definition.table_name} #{definition.table_name.singularize}_history].each do |table|
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table} CASCADE")
    end
    definition.generate_model
  end

  def regenerate(definition)
    fresh = definition.class.find(definition.id)
    fresh.force_regenerate = true
    fresh.generate_model
    fresh
  end

  def issue_for(category, definition)
    described_class.grouped.fetch(category, []).find do |issue|
      issue[:definition_class] == definition.class && issue[:id] == definition.id
    end
  end

  def message_text(line)
    Nokogiri::HTML.fragment(line).text
  end

  def message_for(label)
    described_class.messages.map { |line| message_text(line) }.select { |line| line.include?(" - #{label} (") }
  end

  def admin_edit_path(segment, definition)
    "/admin/#{segment}?filter%5Bid%5D=#{definition.id}&perform_action=edit"
  end

  before(:all) do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    @rand_id = SecureRandom.hex(4)

    @missing_dm = create_dynamic_model('missing')
    drop_table_and_regenerate(@missing_dm)
    @disabled_missing_dm = create_dynamic_model('disabledmissing')
    drop_table_and_regenerate(@disabled_missing_dm)

    @failing_dm = create_dynamic_model('failing')
    @missing_ei = create_external_identifier('eimissing')
    drop_table_and_regenerate(@missing_ei)
    @failing_ei = create_external_identifier('eifailing')
    @failing_al = ActivityLog.create!(
      current_admin: @admin,
      name: "load issue failing al #{@rand_id}",
      item_type: 'player_contact',
      process_name: "loadissuefailing#{@rand_id}",
      schema_name: 'dynamic_test',
      category: :test,
      action_when_attribute: 'created_at',
      extra_log_types: <<~YAML
        step_#{@rand_id}:
          label: Load issue failing
          fields:
            - data
      YAML
    )

    @parse_error_dm = create_dynamic_model('parseerror', options: bad_anchor_options)
    @disabled_parse_error_dm = create_dynamic_model('disabledparse', options: bad_anchor_options)

    @missing_reference_name = "dynamic_model__loadissuenosuchmodel#{@rand_id}"
    @unresolved_dm = create_dynamic_model('unresolved', options: <<~YAML)
      default:
        label: Unresolved reference source
        references:
          #{@missing_reference_name}:
            from: this
            add: many
    YAML

    @forward_target_al = ActivityLog.create!(
      current_admin: @admin,
      name: "load issue forward target #{@rand_id}",
      item_type: 'player_contact',
      process_name: "loadissueforward#{@rand_id}",
      schema_name: 'dynamic_test',
      category: :test,
      action_when_attribute: 'created_at',
      extra_log_types: <<~YAML
        step_#{@rand_id}:
          label: Forward target
          fields:
            - data
      YAML
    )
    @forward_source_dm = create_dynamic_model('forwardsource', options: <<~YAML)
      default:
        label: Forward reference source
        references:
          activity_log__#{@forward_target_al.item_type_name}:
            from: this
            add: many
    YAML

    # A second active definition on the same table shares one implementation class
    @shared_dm = create_dynamic_model('shared')
    @shared_twin_dm = DynamicModel.create!(
      current_admin: @admin,
      name: "load issue shared twin #{@rand_id}",
      table_name: @shared_dm.table_name,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test
    )

    # Definitions are only active when an active app type has access to them
    app_type = Admin::AppType.active.first!
    [@missing_dm, @disabled_missing_dm, @failing_dm, @failing_al, @parse_error_dm, @disabled_parse_error_dm,
     @unresolved_dm, @forward_target_al, @forward_source_dm, @shared_dm, @missing_ei, @failing_ei].each do |definition|
      definition.add_user_access_controls(force: true, app_type:)
    end

    [ExternalIdentifier, DynamicModel, ActivityLog].each(&:reset_active_model_configurations!)
  end

  after(:all) do
    # Reload first: examples disable some of these in memory, but their transactions roll the change back
    [@missing_dm, @disabled_missing_dm, @failing_dm, @failing_al, @parse_error_dm, @disabled_parse_error_dm,
     @unresolved_dm, @forward_target_al, @forward_source_dm, @shared_twin_dm, @shared_dm, @missing_ei,
     @failing_ei].each do |definition|
      definition&.reload&.disable!(@admin)
    end
    change_setting('AllowDynamicMigrations', false)
  end

  before do
    allow(AppControl).to receive_messages(define_models_completed_since_unload?: true, defining_models?: false)
  end

  after do
    # Put the parse error definition and any injected failures back to their starting state
    cached = DynamicModel.definition_cache[@parse_error_dm.id]
    cached.options = bad_anchor_options
    cached.force_option_config_parse(raise_bad_configs: false)
    [@failing_dm, @failing_al, @failing_ei].each do |definition|
      regenerate(definition) if definition.class.generation_failures.key?(definition.id)
    end
  end

  describe 'table_or_view_not_found' do
    it 'reports an active definition whose class was not generated and whose table does not exist' do
      expect(DynamicModel.models).not_to have_key(@missing_dm.implementation_model_name)
      expect(@missing_dm.table_or_view_ready?).to be false

      issue = issue_for(:table_or_view_not_found, @missing_dm)

      expect(issue).to include(definition_class: DynamicModel, resource_name: @missing_dm.resource_name)
      expect(issue_for(:failed_to_create, @missing_dm)).to be_nil
    end

    it 'reports an ExternalIdentifier whose class was not generated and whose table does not exist' do
      expect(ExternalIdentifier.models).not_to have_key(@missing_ei.implementation_model_name)

      expect(issue_for(:table_or_view_not_found, @missing_ei)).to include(resource_name: @missing_ei.name)
    end

    it 'does not report a generated definition' do
      expect(DynamicModel.models).to have_key(@failing_dm.implementation_model_name)

      expect(issue_for(:table_or_view_not_found, @failing_dm)).to be_nil
      expect(issue_for(:failed_to_create, @failing_dm)).to be_nil
    end

    it 'stops reporting a definition that is disabled' do
      expect(issue_for(:table_or_view_not_found, @disabled_missing_dm)).to be_present

      @disabled_missing_dm.disable!(@admin)

      expect(issue_for(:table_or_view_not_found, @disabled_missing_dm)).to be_nil
    end

    it 'does not report definitions that share a generated implementation class' do
      expect(@shared_dm.implementation_model_name).to eq @shared_twin_dm.implementation_model_name
      expect(DynamicModel.models).to have_key(@shared_dm.implementation_model_name)

      %i[table_or_view_not_found failed_to_create].each do |category|
        expect(issue_for(category, @shared_dm)).to be_nil
        expect(issue_for(category, @shared_twin_dm)).to be_nil
      end
    end
  end

  describe 'failed_to_create' do
    def fail_generation(definition, message)
      failing = definition.class.find(definition.id)
      failing.force_regenerate = true
      allow(failing).to receive(:apply_encrypted_attributes).and_raise(StandardError, message)
      failing.generate_model
    end

    it 'reports a DynamicModel whose class build raised, with the exception message' do
      fail_generation(@failing_dm, 'class build failure')

      expect(DynamicModel.models).not_to have_key(@failing_dm.implementation_model_name)
      expect(issue_for(:failed_to_create, @failing_dm)).to include(detail: 'class build failure')
      expect(issue_for(:table_or_view_not_found, @failing_dm)).to be_nil
    end

    it 'reports an ActivityLog whose class build raised, with the exception message' do
      fail_generation(@failing_al, 'activity log build failure')

      expect(ActivityLog.models).not_to have_key(@failing_al.implementation_model_name)
      expect(issue_for(:failed_to_create, @failing_al)).to include(detail: 'activity log build failure')
    end

    it 'reports an ExternalIdentifier whose class build raised, with the exception message' do
      fail_generation(@failing_ei, 'external identifier build failure')

      expect(ExternalIdentifier.models).not_to have_key(@failing_ei.implementation_model_name)
      expect(issue_for(:failed_to_create, @failing_ei)).to include(detail: 'external identifier build failure')
    end

    it 'reports an ActivityLog whose generated class fails the implementation class check' do
      failing = ActivityLog.find(@failing_al.id)
      failing.force_regenerate = true
      allow(failing).to receive(:implementation_class_defined?).and_return(false)
      failing.generate_model

      expect(ActivityLog.models).to have_key(@failing_al.implementation_model_name)
      expect(issue_for(:failed_to_create, @failing_al)[:detail]).to include('implementation class check')
    end

    it 'keeps only the first line of the message, truncated to 200 characters' do
      fail_generation(@failing_dm, "#{'a' * 300}\nsecond line")

      detail = issue_for(:failed_to_create, @failing_dm)[:detail]

      expect(detail.length).to eq 200
      expect(detail).to end_with('...')
      expect(detail).not_to include('second line')
    end

    it 'stops reporting the definition once it regenerates successfully' do
      fail_generation(@failing_dm, 'class build failure')
      expect(issue_for(:failed_to_create, @failing_dm)).to be_present

      regenerate(@failing_dm)

      expect(DynamicModel.models).to have_key(@failing_dm.implementation_model_name)
      expect(DynamicModel.generation_failures).not_to have_key(@failing_dm.id)
      expect(issue_for(:failed_to_create, @failing_dm)).to be_nil
    end

    it 'stops reporting the ActivityLog once it regenerates successfully' do
      fail_generation(@failing_al, 'activity log build failure')
      expect(issue_for(:failed_to_create, @failing_al)).to be_present

      regenerate(@failing_al)

      expect(ActivityLog.generation_failures).not_to have_key(@failing_al.id)
      expect(issue_for(:failed_to_create, @failing_al)).to be_nil
    end
  end

  describe 'options_parse_exception' do
    it 'reports a definition whose options raised on parse, with the exception message' do
      issue = issue_for(:options_parse_exception, @parse_error_dm)

      expect(issue[:detail]).to match(/redefines standard anchors.*&is_blank/)
      expect(DynamicModel.models).to have_key(@parse_error_dm.implementation_model_name)
      expect(issue_for(:failed_to_create, @parse_error_dm)).to be_nil
    end

    it 'stops reporting the definition once a reparse succeeds' do
      cached = DynamicModel.definition_cache.fetch(@parse_error_dm.id)
      cached.options = good_options
      cached.force_option_config_parse(raise_bad_configs: false)

      expect(cached.option_configs_parse_error).to be_nil
      expect(issue_for(:options_parse_exception, @parse_error_dm)).to be_nil
    end

    it 'does not report options that parse but have configuration errors' do
      cached = DynamicModel.definition_cache.fetch(@parse_error_dm.id)
      cached.options = good_options
      allow(cached.class.options_provider).to receive(:bad_configs?).and_return(true)

      cached.force_option_config_parse(raise_bad_configs: false)

      expect(cached.failed_option_configs?).to be true
      expect(cached.option_configs_parse_error).to be_nil
      expect(issue_for(:options_parse_exception, @parse_error_dm)).to be_nil
    end

    it 'does not report validation errors raised for options that did parse' do
      cached = DynamicModel.definition_cache.fetch(@parse_error_dm.id)
      cached.options = good_options
      cached.force_option_config_parse(raise_bad_configs: false)
      allow(cached.class.options_provider).to receive(:raise_bad_configs).and_raise(FphsOptionsBadConfig, 'bad config')

      expect { cached.option_configs(raise_bad_configs: true) }.to raise_error(FphsOptionsBadConfig)

      expect(cached.option_configs_parse_error).to be_nil
      expect(issue_for(:options_parse_exception, @parse_error_dm)).to be_nil
    end

    it 'stops reporting a definition that is disabled' do
      expect(issue_for(:options_parse_exception, @disabled_parse_error_dm)).to be_present

      @disabled_parse_error_dm.disable!(@admin)

      expect(issue_for(:options_parse_exception, @disabled_parse_error_dm)).to be_nil
    end
  end

  describe 'unresolved_references' do
    it 'reports a reference to a missing model after the run, listing the unresolved target' do
      Dynamic::DefGenerator.resolve_cached_forward_references!

      issue = issue_for(:unresolved_references, @unresolved_dm)

      expect(issue[:detail]).to eq @missing_reference_name
      expect(issue_for(:options_parse_exception, @unresolved_dm)).to be_nil
    end

    it 'does not report a forward reference that resolve_cached_forward_references! repaired' do
      target_class_name = @forward_target_al.model_class_name
      target_class = ActivityLog.const_get(target_class_name, false)
      ActivityLog.send(:remove_const, target_class_name)
      DynamicModel.definition_cache.fetch(@forward_source_dm.id).force_option_config_parse(raise_bad_configs: false)

      expect(issue_for(:unresolved_references, @forward_source_dm)).to be_present

      ActivityLog.const_set(target_class_name, target_class)
      Dynamic::DefGenerator.resolve_cached_forward_references!

      expect(issue_for(:unresolved_references, @forward_source_dm)).to be_nil
    ensure
      ActivityLog.const_set(target_class_name, target_class) unless ActivityLog.const_defined?(target_class_name, false)
    end
  end

  describe '.messages' do
    it 'returns one line per non-empty category, in a fixed order, with details' do
      failing = DynamicModel.find(@failing_dm.id)
      failing.force_regenerate = true
      allow(failing).to receive(:apply_encrypted_attributes).and_raise(StandardError, "build failure\nsecond line")
      failing.generate_model

      lines = described_class.messages
      labels = ['table or view not found', 'failure creating definition', 'exception parsing options',
                'references to definitions not available on this server']

      expect(labels.map { |label| lines.count { |line| line.include?(" - #{label} (") } }).to eq [1, 1, 1, 1]
      expect(lines.map { |line| labels.index { |label| line.include?(" - #{label} (") } }).to eq [0, 1, 2, 3]
      expect(lines).to all(start_with('Dynamic definitions not loaded - '))

      expect(message_for(labels[0]).first)
        .to match(/- #{labels[0]} \(\d+\): .*#{@missing_dm.resource_name} \(id #{@missing_dm.id}\)(,|\z)/)
      expect(message_for(labels[1]).first).to include("#{@failing_dm.resource_name} (id #{@failing_dm.id}) - build failure")
      expect(message_for(labels[1]).first).not_to include('second line')
      expect(message_for(labels[2]).first)
        .to include("#{@parse_error_dm.resource_name} (id #{@parse_error_dm.id}) - Configuration redefines standard anchors")
      expect(message_for(labels[3]).first)
        .to include("#{@unresolved_dm.resource_name} (id #{@unresolved_dm.id}) -> #{@missing_reference_name}")
    end

    it 'counts the items in each category' do
      grouped = described_class.grouped

      described_class.messages.each do |line|
        count = line[/\((\d+)\):/, 1].to_i
        category = grouped.keys.find { |key| line.include?(described_class::CATEGORY_LABELS[key]) }
        expect(count).to eq grouped[category].length
      end
    end

    it 'links each definition to its admin edit page' do
      failing = ActivityLog.find(@failing_al.id)
      failing.force_regenerate = true
      allow(failing).to receive(:apply_encrypted_attributes).and_raise(StandardError, 'build failure')
      failing.generate_model

      lines = described_class.messages
      links = lines.flat_map { |line| Nokogiri::HTML.fragment(line).css('a').map { |a| [a.text, a['href']] } }.to_h

      expect(lines).to all(be_html_safe)
      expect(links).to include(
        @missing_dm.resource_name => admin_edit_path('dynamic_models', @missing_dm),
        @missing_ei.resource_name => admin_edit_path('external_identifiers', @missing_ei),
        @failing_al.resource_name => admin_edit_path('activity_logs', @failing_al)
      )
    end

    it 'escapes markup in the definition details' do
      payload = '<img src=x onerror=alert(1)>'
      failing = DynamicModel.find(@failing_dm.id)
      failing.force_regenerate = true
      allow(failing).to receive(:apply_encrypted_attributes).and_raise(StandardError, payload)
      failing.generate_model

      fragment = Nokogiri::HTML.fragment(described_class.messages.join)

      expect(fragment.css('img')).to be_empty
      expect(fragment.text).to include("#{@failing_dm.resource_name} (id #{@failing_dm.id}) - #{payload}")
    end

    it 'does not raise if the report cannot be built' do
      allow(described_class).to receive(:grouped).and_raise(StandardError, 'report failure')

      expect(described_class.messages).to eq []
    end
  end

  describe 'gate' do
    it 'reports nothing until a define_models run has completed' do
      expect(described_class.grouped).not_to be_empty

      allow(AppControl).to receive(:define_models_completed_since_unload?).and_return(false)

      expect(described_class.grouped).to eq({})
      expect(described_class.messages).to eq []
    end

    it 'reports nothing while a define_models run is in progress' do
      allow(AppControl).to receive(:defining_models?).and_return(true)

      expect(described_class.messages).to eq []
    end

    it 'reports nothing during an app type import' do
      allow(Admin::AppTypeImport).to receive(:import_in_progress?).and_return(true)

      expect(described_class.messages).to eq []
    end

    it 'reports nothing during a real define_models run, and reports again once it completes' do
      allow(AppControl).to receive(:define_models_completed_since_unload?).and_call_original
      allow(AppControl).to receive(:defining_models?).and_call_original
      during_run = nil
      allow(ActivityLog).to receive(:define_models) do
        during_run = [AppControl.defining_models?, described_class.messages]
      end

      AppControl.define_models

      expect(during_run).to eq [true, []]
      expect(AppControl.define_models_completed_since_unload?).to be true
      expect(described_class.messages).not_to be_empty
    end
  end

  describe 'Admin::ServerInfo#configuration_failed_reason' do
    it 'includes the dynamic definition lines' do
      reasons = Admin::ServerInfo.new(@admin).configuration_failed_reason

      expect(reasons).to include(*described_class.messages)
      expect(reasons).to include(a_string_matching(/table or view not found.*#{@missing_dm.resource_name}/))
    end

    it 'omits the lines until a define_models run has completed' do
      allow(AppControl).to receive(:define_models_completed_since_unload?).and_return(false)

      reasons = Admin::ServerInfo.new(@admin).configuration_failed_reason

      expect(reasons).not_to include(a_string_starting_with('Dynamic definitions not loaded'))
    end

    it 'is not successful when there are lines to report' do
      allow(Dynamic::DefinitionLoadIssues).to receive(:messages).and_return(['Dynamic definitions not loaded - x (1): y'])

      expect(Admin::ServerInfo.new(@admin).configuration_successful).to be false
    end
  end
end
