# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OptionConfigs::ExtraOptions, type: :model do
  include ModelSupport

  describe 'standard anchor validation' do
    it 'extracts standard anchors from standard definition files' do
      anchors = described_class.extract_standard_anchors

      # Should find anchors defined in extra_options_standard_option_defs.yaml
      expect(anchors).to include('never')
      expect(anchors).to include('never_creatable')
      expect(anchors).to include('is_blank')
      expect(anchors).to include('is_not_blank')
      expect(anchors).to include('is_falsey')
      expect(anchors).to include('is_not_disabled')
      expect(anchors).to include('field_has_no_tags')

      # Should be unique
      expect(anchors.length).to eq(anchors.uniq.length)
    end

    it 'detects when user config redefines a standard anchor' do
      # Valid config that references anchor correctly
      valid_config = <<~YAML
        default:
          show_if:
            field_1:
              this:
                status: *is_blank
      YAML

      redefined = described_class.check_for_redefined_anchors(valid_config)
      expect(redefined).to be_empty

      # Invalid config that redefines anchor
      invalid_config = <<~YAML
        default:
          show_if:
            field_1:
              this:
                status: &is_blank
      YAML

      redefined = described_class.check_for_redefined_anchors(invalid_config)
      expect(redefined).to include('is_blank')
    end

    it 'detects multiple redefined anchors' do
      invalid_config = <<~YAML
        default:
          show_if:
            field_1:
              this:
                status: &is_blank
            field_2:
              this:
                enabled: &never
      YAML

      redefined = described_class.check_for_redefined_anchors(invalid_config)
      expect(redefined).to include('is_blank')
      expect(redefined).to include('never')
      expect(redefined.length).to eq(2)
    end

    it 'correctly handles user definitions sections without false positives' do
      # User can have their own _definitions section with different anchor names
      config_with_user_defs = <<~YAML
        _definitions___user_definitions___:
          my_custom_blank: &my_blank
            - null
            - ''
        default:
          show_if:
            field_1:
              this:
                status: *is_blank
      YAML

      redefined = described_class.check_for_redefined_anchors(config_with_user_defs)
      expect(redefined).to be_empty
    end

    it 'raises parse error when config redefines standard anchors' do
      create_admin

      invalid_options_text = <<~YAML
        default:
          fields:
            - field_1
            - field_2
          show_if:
            field_2:
              this:
                field_1: &is_blank
      YAML

      dm = DynamicModel.new(
        name: 'test_anchor_validation',
        table_name: 'test_anchor_validation',
        schema_name: 'dynamic_test',
        options: invalid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.to raise_error(FphsOptionsParseError) do |error|
        expect(error.message).to match(/redefines standard anchors.*&is_blank/)
        # The backtrace should include the problem lines with line numbers
        backtrace_str = error.backtrace.join("\n")
        expect(backtrace_str).to match(/field_1: &is_blank/)
        expect(backtrace_str).to match(/^\d+:/) # Should include line number
      end
    end

    it 'does not raise error when config uses standard anchors correctly' do
      create_admin

      valid_options_text = <<~YAML
        default:
          fields:
            - field_1
            - field_2
          show_if:
            field_2:
              this:
                field_1: *is_blank
      YAML

      dm = DynamicModel.new(
        name: 'test_anchor_validation_valid',
        table_name: 'test_anchor_validation_valid',
        schema_name: 'dynamic_test',
        options: valid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs
      end.not_to raise_error
    end

    it 'detects anchor redefinition with different whitespace patterns' do
      # Test various ways anchors might be accidentally redefined
      patterns = [
        'status: &is_blank',      # standard pattern
        "status: &is_blank\n",    # with newline
        'status:&is_blank',       # no space before anchor
        'status:  &is_blank' # extra spaces
      ]

      patterns.each do |pattern|
        config = "default:\n  show_if:\n    field_1:\n      this:\n        #{pattern}"
        redefined = described_class.check_for_redefined_anchors(config)
        expect(redefined).to include('is_blank'), "Failed to detect pattern: #{pattern}"
      end
    end

    it 'correctly distinguishes between anchor definition and reference' do
      # Should NOT detect *is_blank (reference) as a redefinition
      config_with_references = <<~YAML
        default:
          show_if:
            field_1:
              this:
                status: *is_blank
            field_2:
              all:
                this:
                  value: *is_blank
                  another: *never
      YAML

      redefined = described_class.check_for_redefined_anchors(config_with_references)
      expect(redefined).to be_empty
    end

    it 'finds and formats the specific lines with anchor redefinitions' do
      config = <<~YAML
        default:
          fields:
            - field_1
            - field_2
          show_if:
            field_1:
              this:
                status: &is_blank
            field_2:
              this:
                enabled: &never
      YAML

      problem_lines = described_class.find_anchor_redefinition_lines(config, ['is_blank', 'never'])

      expect(problem_lines).to include('status: &is_blank')
      expect(problem_lines).to include('enabled: &never')
      expect(problem_lines).to match(/^\d+:/) # Should have line numbers
      expect(problem_lines.scan(/^\d+:/).length).to eq(2) # Two problem lines
    end

    it 'handles multiple redefinitions of the same anchor on different lines' do
      config = <<~YAML
        option_1:
          show_if:
            field_1:
              this:
                status: &is_blank
        option_2:
          show_if:
            field_2:
              this:
                value: &is_blank
      YAML

      problem_lines = described_class.find_anchor_redefinition_lines(config, ['is_blank'])

      # Should find both occurrences
      expect(problem_lines.scan('&is_blank').length).to eq(2)
      expect(problem_lines.scan(/^\d+:/).length).to eq(2)
    end
  end
end
