# frozen_string_literal: true

# Regression specs for issue #1525: an options-only commit on a dynamic definition must reset the
# memoized (loaded) active_model_configurations relation, so the page template does not keep rendering
# stale option values (such as captions) in the process that handled the save. DynamicModel,
# ActivityLog and ExternalIdentifier each use a different attribute for their options text.
require 'rails_helper'

RSpec.describe 'Dynamic definition options cache invalidation', type: :model do
  include ModelSupport

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', false)
    @admin, = create_admin
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  after do
    [DynamicModel, ActivityLog, ExternalIdentifier].each(&:reset_active_model_configurations!)
  end

  def first_active_definition(definition_class)
    definition = definition_class.active_model_configurations.load.first
    expect(definition).to be_present, "expected an active #{definition_class} definition in the test database"
    definition
  end

  def expect_options_commit_to_refresh(definition_class)
    cached_relation = definition_class.active_model_configurations.load
    definition = first_active_definition(definition_class)
    attribute = definition_class.option_configs_attr
    changed_options = "#{definition.public_send(attribute)}\n# issue1525 #{SecureRandom.hex(4)}"

    edited_definition = definition_class.find(definition.id)
    edited_definition.current_admin = @admin
    edited_definition.public_send("#{attribute}=", changed_options)
    edited_definition.save!

    refreshed_relation = definition_class.active_model_configurations.load
    expect(refreshed_relation).not_to equal(cached_relation)
    expect(refreshed_relation.detect { |record| record.id == definition.id }&.options_text).to eq(changed_options)
  end

  it 'clears DynamicModel active configurations after an options-only commit' do
    expect_options_commit_to_refresh(DynamicModel)
  end

  it 'clears ActivityLog active configurations after an extra_log_types-only commit' do
    expect_options_commit_to_refresh(ActivityLog)
  end

  it 'clears ExternalIdentifier active configurations after an options-only commit' do
    expect_options_commit_to_refresh(ExternalIdentifier)
  end

  it 'does not clear active configurations when a non-options field changes' do
    cached_relation = DynamicModel.active_model_configurations.load
    definition = DynamicModel.find(first_active_definition(DynamicModel).id)
    definition.current_admin = @admin
    definition.position = definition.position.to_i + 1

    definition.save!

    expect(DynamicModel.active_model_configurations).to equal(cached_relation)
  end
end
