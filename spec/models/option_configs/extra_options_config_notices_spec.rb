# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for config notice enrichment in ExtraOptions.
# Verifies that errors and warnings produced by BaseConfiguration subclasses
# are enriched with the parent context fields required by the admin panel
# template (_config_notices.html.erb): :name, :resource_name, :config_class,
# :config_object, :config_resource_name, :config_def.
# Also verifies that messages include config section and field name context
# so administrators can identify the source of configuration problems.
RSpec.describe 'ExtraOptions config notice enrichment', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:each) do
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
    @dm = generate_test_dynamic_model
    setup_access :dynamic_model__test_created_by_recs, user: @user
  end

  describe 'caption_before with unrecognized attributes' do
    let(:yaml) do
      <<~YAML
        default:
          caption_before:
            no_field:
              do this: true
      YAML
    end

    it 'enriches warnings with all template-required fields' do
      oc = config_for(yaml)
      warnings = oc.config_warnings

      expect(warnings).not_to be_empty

      warning = warnings.find { |w| w[:message].include?('do this') }
      expect(warning).not_to be_nil

      # All fields required by _config_notices.html.erb must be present
      expect(warning[:name]).to eq :default
      expect(warning[:resource_name]).to be_present
      expect(warning[:config_class]).to be_present
      expect(warning[:config_object]).to eq @dm
      expect(warning[:config_resource_name]).to be_present
      expect(warning[:config_def]).to be_a(Hash)
    end

    it 'sets :type to config section path for template heading' do
      oc = config_for(yaml)
      warning = oc.config_warnings.find { |w| w[:message].include?('do this') }

      # :type identifies the config section and field for the template title
      # Template renders: "{resource_name} - {name} - {type}"
      expect(warning[:type]).to eq 'caption_before > no_field'
      # Message is just the error detail, no redundant prefix
      expect(warning[:message]).to eq "unrecognized attribute 'do this'"
    end

    it 'builds config_def as a string-keyed nested hash showing the config path' do
      oc = config_for(yaml)
      warning = oc.config_warnings.find { |w| w[:message].include?('do this') }

      # config_def mirrors the YAML structure with string keys for clean YAML rendering
      expect(warning[:config_def]).to eq('caption_before' => { 'no_field' => { 'do this' => true } })
      # Renders clean YAML without symbol prefixes
      yaml_output = warning[:config_def].to_yaml
      expect(yaml_output).to include('caption_before:')
      expect(yaml_output).to include('no_field:')
      expect(yaml_output).to include('do this:')
      expect(yaml_output).not_to include(':caption_before')
    end
  end

  describe 'label with non-string value' do
    let(:yaml) do
      <<~YAML
        default:
          label:
            is_wrong: true
      YAML
    end

    it 'produces a warning with label section as :type' do
      oc = config_for(yaml)
      warnings = oc.config_warnings

      label_warning = warnings.find { |w| w[:message].include?('label must be a string') }
      expect(label_warning).not_to be_nil
      expect(label_warning[:type]).to eq 'label'
      expect(label_warning[:message]).to eq 'label must be a string, got hash'
    end

    it 'builds config_def showing the label config value with string keys' do
      oc = config_for(yaml)
      label_warning = oc.config_warnings.find { |w| w[:message].include?('label must be a string') }

      # Shows what was passed as the label value, with string keys
      expect(label_warning[:config_def]).to eq('label' => { 'is_wrong' => true })
      yaml_output = label_warning[:config_def].to_yaml
      expect(yaml_output).to include('label:')
      expect(yaml_output).not_to include(':label')
    end

    it 'enriches label warning with all template-required fields' do
      oc = config_for(yaml)
      label_warning = oc.config_warnings.find { |w| w[:message].include?('label must be a string') }

      expect(label_warning[:name]).to eq :default
      expect(label_warning[:resource_name]).to be_present
      expect(label_warning[:config_class]).to be_present
      expect(label_warning[:config_object]).to eq @dm
      expect(label_warning[:config_def]).to be_a(Hash)
    end
  end

  describe 'all_option_configs_notices returns enriched notices' do
    let(:yaml) do
      <<~YAML
        default:
          label:
            is_wrong: true
          caption_before:
            no_field:
              do this: true
      YAML
    end

    it 'returns notices with all template-required keys via all_option_configs_notices' do
      @dm.update!(options: yaml, current_admin: @admin)
      notices = OptionConfigs::ExtraOptions.all_option_configs_notices(@dm)

      expect(notices).not_to be_nil
      expect(notices.length).to be >= 2

      notices.each do |notice|
        expect(notice).to have_key(:name), "notice missing :name — #{notice[:message]}"
        expect(notice).to have_key(:resource_name), "notice missing :resource_name — #{notice[:message]}"
        expect(notice).to have_key(:config_def), "notice missing :config_def — #{notice[:message]}"
        expect(notice[:name]).to be_present, "notice :name is blank — #{notice[:message]}"
      end
    end

    it 'does not raise when template calls .to_s.id_hyphenate on notice fields' do
      @dm.update!(options: yaml, current_admin: @admin)
      notices = OptionConfigs::ExtraOptions.all_option_configs_notices(@dm)

      notices.each do |notice|
        # Simulate what _config_notices.html.erb does
        expect { notice[:name].to_s.id_hyphenate }.not_to raise_error
        expect { notice[:type].to_s.id_hyphenate }.not_to raise_error
        expect { notice[:resource_name].to_s }.not_to raise_error
        expect { notice[:config_def].to_yaml }.not_to raise_error
      end
    end
  end

  describe 'valid configuration produces no notices' do
    let(:yaml) do
      <<~YAML
        default:
          label: My Label
          caption_before:
            test1: Some caption text
      YAML
    end

    it 'does not produce errors or warnings for valid config' do
      oc = config_for(yaml)
      expect(oc.config_errors).to be_empty
      expect(oc.config_warnings).to be_empty
    end
  end
end
