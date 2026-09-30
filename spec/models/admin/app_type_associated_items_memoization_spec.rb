# frozen_string_literal: true

# Tests for memoization added to Admin::AppType#associated_reports,
# #associated_message_templates and #associated_config_libraries.
#
# These methods previously recomputed their result from scratch on every call (unlike
# #associated_activity_logs / #associated_dynamic_models, which already used
# #memoize_associated_items), even though they are called multiple times per admin
# components-panel render (directly, and again from each other). These specs confirm
# a second call reuses the memoized result instead of re-querying, and that saving an
# Admin::MessageTemplate correctly invalidates the memo (since it isn't reached via the
# existing ActivityLog/DynamicModel/UserAccessControl invalidation hooks).

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

  describe '#cached_definition' do
    it 'returns the ActivityLog.definition_cache instance for the given record, if registered' do
      al = @app_type.associated_activity_logs.all.first
      cached = al && ActivityLog.definition_cache[al.id]
      skip 'No ActivityLog registered in definition_cache in this test context' unless cached

      expect(@app_type.cached_definition(al)).to equal(cached)
    end

    it 'falls back to the given record when nothing is registered in definition_cache' do
      al = @app_type.associated_activity_logs.all.first
      skip 'No associated activity log in this test context' unless al

      original = ActivityLog.definition_cache.delete(al.id)

      expect(@app_type.cached_definition(al)).to equal(al)
    ensure
      ActivityLog.definition_cache[al.id] = original if al && original
    end
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
end

RSpec.describe Admin::MessageTemplate, type: :model do
  include ModelSupport

  it 'invalidates Admin::AppType associated item memoization on save' do
    create_admin
    mt = Admin::MessageTemplate.active.first ||
         Admin::MessageTemplate.create!(name: 'test template', message_type: 'plain',
                                        template_type: 'content', current_admin: @admin)

    expect(Admin::AppType).to receive(:reset_memo_associated_items!)
    mt.current_admin = @admin
    mt.touch
  end
end
