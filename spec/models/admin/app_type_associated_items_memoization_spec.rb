# frozen_string_literal: true

# Tests for memoization added to Admin::AppType#associated_reports,
# Tests Admin::AppType associated-item memoization and message-template discovery, including
# cached-definition reuse and panel-only filtering of definitions not generated on this server.

require 'rails_helper'

RSpec.describe Admin::AppType, type: :model do
  include ModelSupport

  before :each do
    create_admin
    @app_type = Admin::AppType.active.first
    Admin::AppType.reset_memo_associated_items!
  end

  describe '#associated_reports' do
    it 'memoizes the result instead of re-querying on a second call' do
      @app_type.associated_reports

      expect(Report).not_to receive(:active)
      @app_type.associated_reports
    end
  end

  describe '#associated_message_templates' do
    it 'memoizes the result instead of re-querying on a second call' do
      @app_type.associated_message_templates

      expect(Admin::MessageTemplate).not_to receive(:active)
      @app_type.associated_message_templates
    end
  end

  describe '#associated_config_libraries' do
    it 'memoizes the result instead of recomputing on a second call' do
      @app_type.associated_config_libraries

      expect(@app_type).not_to receive(:associated_activity_logs)
      @app_type.associated_config_libraries
    end
  end

  describe '#reset_associated_item_memos!' do
    it 'clears this instance memo so the next build recomputes associated reports' do
      @app_type.instance_variable_set(:@associated_reports, :stale)
      @app_type.reset_associated_item_memos!

      expect(@app_type.instance_variable_get(:@associated_reports)).to be_nil
    end

    it 'resets the skipped message-template definition count' do
      @app_type.instance_variable_set(:@skipped_message_template_definition_count, 2)

      @app_type.reset_associated_item_memos!

      expect(@app_type.skipped_message_template_definition_count).to eq(0)
    end

    it 'is called at the start of JSON serialization' do
      expect(@app_type).to receive(:reset_associated_item_memos!).and_call_original

      @app_type.as_json(main_components: true,
                        exclude_components: %i[associated_sub_processes associated_protocol_events])
    end
  end
end

RSpec.describe ActivityLog, type: :model do
  include ModelSupport

  before do
    create_admin
    @app_type = Admin::AppType.active.first
  end

  describe '.cached_definition_for' do
    it 'returns the parsed definition_cache instance when timestamps match' do
      al = @app_type.associated_activity_logs.all.first
      cached = al && ActivityLog.definition_cache[al.id]
      skip 'No ActivityLog registered in definition_cache in this test context' unless cached

      expect(described_class.cached_definition_for(al)).to equal(cached)
    end

    it 'uses a freshly queried definition when its timestamp differs from the cached instance' do
      al = @app_type.associated_activity_logs.all.first
      skip 'No associated activity log in this test context' unless al

      cached = ActivityLog.definition_cache[al.id]
      skip 'No ActivityLog registered in definition_cache in this test context' unless cached
      fresh = al.dup
      fresh.updated_at = cached.updated_at + 1.second

      expect(described_class.cached_definition_for(fresh)).to equal(fresh)
    end

    it 'returns the passed definition when it is not in definition_cache' do
      activity_log = ActivityLog.active.first!
      cached = ActivityLog.definition_cache.delete(activity_log.id)

      expect(described_class.cached_definition_for(activity_log)).to equal(activity_log)
    ensure
      ActivityLog.definition_cache[activity_log.id] = cached if cached
    end
  end
end

RSpec.describe Admin::AppType, type: :model do
  include ModelSupport

  before :each do
    create_admin
    @app_type = Admin::AppType.active.first
    Admin::AppType.reset_memo_associated_items!
  end

  describe '#associated_message_templates reuse of already-parsed definitions' do
    it 'does not re-parse option_configs for an activity log already cached in ActivityLog.definition_cache' do
      al = @app_type.associated_activity_logs.all.first
      skip 'No associated activity log in this test context' unless al

      cached = ActivityLog.definition_cache[al.id]
      skip 'Activity log not registered in definition_cache in this test context' unless cached

      cached.option_configs # prime the cached instance's own memo

      expect(al).not_to receive(:option_configs)

      @app_type.associated_message_templates
    end
  end

  describe '#associated_message_templates hash-index lookup branches' do
    # Minimal stand-ins for ActivityLog/DynamicModel/Report + their parsed option_configs,
    # to exercise the dialog_before / save_trigger notify (layout+content) / report
    # template_block hash-lookup branches directly, without needing a full dynamic migration.
    # The fake class returns itself from cached_definition_for, avoiding any dynamic model setup.
    let(:fake_option_config_class) { Struct.new(:dialog_before, :save_trigger) }
    let(:fake_definition_class) do
      Struct.new(:id, :option_configs) do
        def self.definition_cache
          @definition_cache ||= {}
        end

        def self.cached_definition_for(definition)
          definition
        end
      end
    end
    let(:fake_report_class) { Struct.new(:id, :description) }

    def stub_all(app_type, method, items)
      relation = items.dup
      relation.define_singleton_method(:all) { relation }
      allow(app_type).to receive(method).and_return(relation)
    end

    def create_dialog_template(name)
      Admin::MessageTemplate.create!(name:, message_type: 'dialog', template_type: 'content',
                                     template: 'x', current_admin: @admin)
    end

    def definition_with_dialog_template(id, template_name)
      option_config = fake_option_config_class.new({ field1: { name: template_name } }, {})
      fake_definition_class.new(id, [option_config])
    end

    it 'matches activity log dialog_before, save_trigger notify (layout+content), dynamic model dialog_before, and report template_block references' do
      dialog_mt = Admin::MessageTemplate.create!(name: 'al_dialog_mt', message_type: 'dialog', template_type: 'content',
                                                 template: 'x', current_admin: @admin)
      layout_mt = Admin::MessageTemplate.create!(name: 'notify_layout_mt', message_type: 'email', template_type: 'layout',
                                                 template: 'x', current_admin: @admin)
      content_mt = Admin::MessageTemplate.create!(name: 'notify_content_mt', message_type: 'email', template_type: 'content',
                                                  template: 'x', current_admin: @admin)
      dm_dialog_mt = Admin::MessageTemplate.create!(name: 'dm_dialog_mt', message_type: 'dialog', template_type: 'content',
                                                    template: 'x', current_admin: @admin)
      block_mt = Admin::MessageTemplate.create!(name: 'my_report_block', message_type: 'plain', template_type: 'content',
                                                template: 'x', current_admin: @admin)

      al_option_config = fake_option_config_class.new(
        { field1: { name: 'al_dialog_mt' } },
        { trigger1: { notify: [{ layout_template: 'notify_layout_mt', content_template: 'notify_content_mt', type: 'email' }] } }
      )
      al = fake_definition_class.new(-101, [al_option_config])

      dm_option_config = fake_option_config_class.new({ field1: { name: 'dm_dialog_mt' } }, {})
      dm = fake_definition_class.new(-102, [dm_option_config])

      report = fake_report_class.new(-103, 'See {{template\_block\_my_report_block}} for details')

      stub_all(@app_type, :associated_activity_logs, [al])
      stub_all(@app_type, :associated_dynamic_models, [dm])
      stub_all(@app_type, :associated_reports, [report])

      result = @app_type.associated_message_templates

      expect(result).to include(dialog_mt, layout_mt, content_mt, dm_dialog_mt, block_mt)
    end

    it 'filters ungenerated definitions only for the requested serialization and reports them' do
      uncached_activity_template = create_dialog_template("uncached_activity_#{SecureRandom.hex(4)}")
      generated_activity_template = create_dialog_template("generated_activity_#{SecureRandom.hex(4)}")
      uncached_dynamic_template = create_dialog_template("uncached_dynamic_#{SecureRandom.hex(4)}")
      generated_dynamic_template = create_dialog_template("generated_dynamic_#{SecureRandom.hex(4)}")

      uncached_activity_log = definition_with_dialog_template(-101, uncached_activity_template.name)
      generated_activity_log = definition_with_dialog_template(-102, generated_activity_template.name)
      uncached_dynamic_model = definition_with_dialog_template(-103, uncached_dynamic_template.name)
      generated_dynamic_model = definition_with_dialog_template(-104, generated_dynamic_template.name)
      fake_definition_class.definition_cache[generated_activity_log.id] = generated_activity_log
      fake_definition_class.definition_cache[generated_dynamic_model.id] = generated_dynamic_model

      stub_all(@app_type, :associated_activity_logs, [uncached_activity_log, generated_activity_log])
      stub_all(@app_type, :associated_dynamic_models, [uncached_dynamic_model, generated_dynamic_model])
      stub_all(@app_type, :associated_reports, [])
      allow(@app_type).to receive(:associated_config_libraries).and_return([])
      allow(@app_type).to receive(:name).and_return("fake_app_type_#{SecureRandom.hex(4)}")
      allow(uncached_activity_log).to receive(:option_configs).and_call_original
      allow(uncached_dynamic_model).to receive(:option_configs).and_call_original

      options = { generated_definitions_only: true, main_components: true,
                  exclude_components: %i[associated_sub_processes associated_protocol_events] }
      @app_type.as_json(options)

      expect(options).not_to have_key(:generated_definitions_only)
      expect(uncached_activity_log).not_to have_received(:option_configs)
      expect(uncached_dynamic_model).not_to have_received(:option_configs)
      expect(@app_type.associated_message_templates)
        .to contain_exactly(generated_activity_template, generated_dynamic_template)
      expect(@app_type.skipped_message_template_definition_count).to eq(2)

      @app_type.as_json(main_components: true)

      expect(@app_type.associated_message_templates).to contain_exactly(
        uncached_activity_template, generated_activity_template,
        uncached_dynamic_template, generated_dynamic_template
      )
      expect(uncached_activity_log).to have_received(:option_configs).once
      expect(uncached_dynamic_model).to have_received(:option_configs).once
      expect(@app_type.skipped_message_template_definition_count).to eq(0)
    end
  end
end
