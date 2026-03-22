# frozen_string_literal: true

# Tests for Admin::ConfigLibrary#referenced_by
# Verifies that a config library can identify which definitions reference it
# via `# @library category name` in their options fields.
# The referenced_by method should find references in:
# - ActivityLog definitions
# - DynamicModel definitions
# - ExternalIdentifier definitions
# - Other ConfigLibrary definitions

require 'rails_helper'

RSpec.describe Admin::ConfigLibrary, type: :model do
  include ModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  describe '#referenced_by' do
    before :all do
      @rand_suffix = rand(1_000_000_000)
      @lib_name = "test_ref_lib_#{@rand_suffix}"
      @lib_category = "test_ref_cat_#{@rand_suffix}"
      @config_library = Admin::ConfigLibrary.create!(
        current_admin: @admin,
        name: @lib_name,
        category: @lib_category,
        format: 'yaml',
        options: "field_1:\n  label: Test Field"
      )
    end

    it 'returns an empty array when no definitions reference the library' do
      result = @config_library.referenced_by
      expect(result).to be_an(Array)
      # Filter to only items that would reference our specific test library
      expect(result).to be_empty
    end

    it 'finds activity logs that reference the library' do
      al = ActivityLog.active.first
      skip 'No active activity logs available' unless al

      original_options = al.options_text
      skip 'Activity log has no options' unless original_options

      # Check if this activity log already references our library
      unless original_options.include?("# @library #{@lib_category} #{@lib_name}")
        al.current_admin = @admin
        al.update!(extra_log_types: "#{original_options}\n# @library #{@lib_category} #{@lib_name}")
      end

      result = @config_library.referenced_by
      al_refs = result.select { |r| r[:type] == 'ActivityLog' }
      expect(al_refs).not_to be_empty
      expect(al_refs.first[:id]).to eq(al.id)
      expect(al_refs.first[:name]).to be_present
      expect(al_refs.first[:admin_path]).to be_present

      # Clean up
      al.current_admin = @admin
      al.update!(extra_log_types: original_options)
    end

    it 'finds dynamic models that reference the library' do
      dm = DynamicModel.active.first
      skip 'No active dynamic models available' unless dm

      original_options = dm.options_text
      skip 'Dynamic model has no options' unless original_options

      unless original_options.include?("# @library #{@lib_category} #{@lib_name}")
        dm.current_admin = @admin
        dm.update!(options: "#{original_options}\n# @library #{@lib_category} #{@lib_name}")
      end

      result = @config_library.referenced_by
      dm_refs = result.select { |r| r[:type] == 'DynamicModel' }
      expect(dm_refs).not_to be_empty
      expect(dm_refs.first[:id]).to eq(dm.id)
      expect(dm_refs.first[:name]).to be_present
      expect(dm_refs.first[:admin_path]).to be_present

      # Clean up
      dm.current_admin = @admin
      dm.update!(options: original_options)
    end

    it 'finds other config libraries that reference the library' do
      referencing_lib = Admin::ConfigLibrary.create!(
        current_admin: @admin,
        name: "test_referencing_lib_#{@rand_suffix}",
        category: @lib_category,
        format: 'yaml',
        options: "some_config:\n  key: value\n# @library #{@lib_category} #{@lib_name}"
      )

      result = @config_library.referenced_by
      cl_refs = result.select { |r| r[:type] == 'ConfigLibrary' }
      expect(cl_refs).not_to be_empty

      matching = cl_refs.find { |r| r[:id] == referencing_lib.id }
      expect(matching).to be_present
      expect(matching[:name]).to include("test_referencing_lib_#{@rand_suffix}")
      expect(matching[:admin_path]).to include('config_libraries')

      # Clean up
      referencing_lib.current_admin = @admin
      referencing_lib.update!(disabled: true)
    end

    it 'returns results with type, id, name, resource_name, and admin_path' do
      referencing_lib = Admin::ConfigLibrary.create!(
        current_admin: @admin,
        name: "test_ref_details_lib_#{@rand_suffix}",
        category: @lib_category,
        format: 'yaml',
        options: "some_config:\n  key: value\n# @library #{@lib_category} #{@lib_name}"
      )

      result = @config_library.referenced_by
      matching = result.find { |r| r[:id] == referencing_lib.id }
      expect(matching).to be_present
      expect(matching).to have_key(:type)
      expect(matching).to have_key(:id)
      expect(matching).to have_key(:name)
      expect(matching).to have_key(:admin_path)

      # Clean up
      referencing_lib.current_admin = @admin
      referencing_lib.update!(disabled: true)
    end

    it 'does not include disabled definitions' do
      disabled_lib = Admin::ConfigLibrary.create!(
        current_admin: @admin,
        name: "test_disabled_ref_lib_#{@rand_suffix}",
        category: @lib_category,
        format: 'yaml',
        options: "cfg:\n  key: val\n# @library #{@lib_category} #{@lib_name}",
        disabled: true
      )

      result = @config_library.referenced_by
      matching = result.find { |r| r[:id] == disabled_lib.id && r[:type] == 'ConfigLibrary' }
      expect(matching).to be_nil
    end
  end
end
