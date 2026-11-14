# frozen_string_literal: true

require 'rails_helper'

# Purpose: verify Dynamic::DefinitionCacheVersion, the single cache version token shared by
# every cache that depends on the set of dynamic definitions (dynamic models, activity logs and
# external identifiers), for example viewable tables, access control resource names, the
# select-from-model options and the selector config overrides.
#
# These specs verify that:
# - the token is stable until it is explicitly rotated
# - rotate! changes the token
# - saving a DynamicModel, ActivityLog or ExternalIdentifier rotates the token
# - saving a YAML config library used by a definition rotates the token once, and saving a
#   library used by no definition does not
RSpec.describe Dynamic::DefinitionCacheVersion, type: :model do
  include ModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin

    # Hex suffix avoids the "numbers preceded by an underscore" name validation
    @rand_id = SecureRandom.hex(4)
    @library_options = "_definitions_lib:\n  dcv_label: &dcv_label Original Label\n"
    @used_library = Admin::ConfigLibrary.create!(
      current_admin: @admin, name: "dcvlib#{@rand_id}", category: "dcvcat#{@rand_id}",
      format: 'yaml', options: @library_options
    )
    @unused_library = Admin::ConfigLibrary.create!(
      current_admin: @admin, name: "dcvother#{@rand_id}", category: "dcvcat#{@rand_id}",
      format: 'yaml', options: "other_config:\n  label: Other Label"
    )
    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: "test dcv #{@rand_id}",
      table_name: "test_dcv#{@rand_id}s",
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: <<~YAML
        # @library dcvcat#{@rand_id} dcvlib#{@rand_id}
        _configurations:
          use_current_version: true
        default:
          label: *dcv_label
      YAML
    )
    DynamicModel.refresh_outdated
  end

  after :all do
    @dm&.disable!(@admin)
    change_setting('AllowDynamicMigrations', false)
  end

  it 'returns a stable token until rotated' do
    expect(described_class.token).to be_present
    expect(described_class.token).to eq(described_class.token)
  end

  it 'changes the token when rotated' do
    token_before = described_class.token

    described_class.rotate!

    expect(described_class.token).not_to eq(token_before)
  end

  {
    'DynamicModel' => lambda {
      definition = DynamicModel.active.first!
      definition.current_admin = @admin
      definition.update!(position: definition.position.to_i + 1)
    },
    'ActivityLog' => lambda {
      definition = ActivityLog.active.first!
      definition.current_admin = @admin
      definition.update!(main_log_name: "#{definition.main_log_name} Changed")
    },
    'ExternalIdentifier' => lambda {
      definition = ExternalIdentifier.active.first!
      definition.current_admin = @admin
      definition.update!(label: "#{definition.label} Changed")
    }
  }.each do |class_name, save_definition|
    it "rotates the token when a #{class_name} is saved" do
      token_before = described_class.token

      instance_exec(&save_definition)

      expect(described_class.token).not_to eq(token_before)
    end
  end

  it 'rotates the token once when a YAML config library used by a definition is saved' do
    token_before = described_class.token
    allow(described_class).to receive(:rotate!).and_call_original

    @used_library.reload
    @used_library.current_admin = @admin
    @used_library.update!(options: @library_options.sub('Original Label', 'Refreshed Label'))

    expect(described_class.token).not_to eq(token_before)
    expect(described_class).to have_received(:rotate!).once
  end

  it 'keeps the token when a YAML config library used by no definition is saved' do
    token_before = described_class.token

    @unused_library.reload
    @unused_library.current_admin = @admin
    @unused_library.update!(options: "other_config:\n  label: Other Label Changed")

    expect(described_class.token).to eq(token_before)
  end
end
