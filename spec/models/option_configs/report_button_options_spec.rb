# frozen_string_literal: true

# Covers the new report button option registry, validation, legacy isolation,
# generated all-null skeleton, and documentation/registry drift for issue #1522.

require 'rails_helper'

RSpec.describe OptionConfigs::ReportOptions, type: :model do
  describe 'new report button option registry' do
    it 'registers the new options in their context-specific configuration blocks' do
      view_options = described_class::ViewOptions.configure_with_items
      search_panel_options = described_class::SearchPanelOptions.configure_with_items
      embedded_options = described_class::EmbeddedOptions.configure_with_items

      expect(view_options).to include(
        :hide_report_button, :hide_count_button, :show_list_records_button,
        :report_button_label, :list_records_button_label, :no_report_results_scroll,
        :auto_submit_on_load, :auto_submit_on_change, :auto_submit_target
      )
      expect(search_panel_options).to eq(
        %i[search_records_button_label hide_search_records_button
           prevent_collapse_for_search_panel_results auto_submit_on_load auto_submit_on_change]
      )
      expect(embedded_options).to eq(
        %i[hide_report_button report_button_label auto_submit_on_load auto_submit_on_change]
      )
      expect(described_class.option_types[:multi]).to include(:search_panel_options, :embedded_options)
    end

    it 'publishes the legacy view option names explicitly' do
      expect(described_class::LEGACY_VIEW_OPTIONS).to eq(
        %i[hide_search_button hide_master_results_list_search_button force_show_search_button
           search_button_label report_auto_submit_on_change no_results_scroll prevent_collapse_for_list]
      )
    end
  end

  describe '.raise_bad_configs' do
    it 'accepts nil and boolean auto-submit flags in every context and valid targets' do
      options = build_options(
        view_options: { auto_submit_on_load: true, auto_submit_on_change: nil, auto_submit_target: 'report' },
        search_panel_options: { auto_submit_on_load: false, auto_submit_on_change: true },
        embedded_options: { auto_submit_on_load: nil, auto_submit_on_change: false }
      )

      expect { described_class.raise_bad_configs(options) }.not_to raise_error
    end

    it 'retains the legacy result handler validation for non-array values' do
      options = build_options(view_options: { result_handlers: '' })

      expect { described_class.raise_bad_configs(options) }
        .to raise_error(FphsException, /result_handlers must be an array/)
    end

    it 'rejects auto-submit targets outside report and list_records' do
      options = build_options(view_options: { auto_submit_target: 'count' })

      expect { described_class.raise_bad_configs(options) }.to raise_error(FphsException, /auto_submit_target/)
    end

    it 'rejects non-boolean auto-submit flags in each context' do
      context_flags = {
        view_options: %i[auto_submit_on_load auto_submit_on_change],
        search_panel_options: %i[auto_submit_on_load auto_submit_on_change],
        embedded_options: %i[auto_submit_on_load auto_submit_on_change]
      }

      context_flags.each do |context, flags|
        flags.each do |flag|
          options = build_options(context => { flag => 'yes' })

          expect { described_class.raise_bad_configs(options) }
            .to raise_error(FphsException, /#{flag}/)
        end
      end
    end
  end

  describe 'legacy and unrecognized options' do
    it 'continues to parse existing legacy options when the new options are absent' do
      options = build_options(view_options: { hide_search_button: true })

      expect(options.view_options.hide_search_button).to be(true)
      expect { described_class.raise_bad_configs(options) }.not_to raise_error
    end
  end

  describe 'new report options skeleton' do
    it 'lists each non-legacy view option plus the search panel and embedded options' do
      skeleton_text = described_class.new_report_options_skeleton
      skeleton = YAML.safe_load(skeleton_text, permitted_classes: [], permitted_symbols: [], aliases: true)
      registered_view_options = described_class::ViewOptions.configure_with_items - described_class::LEGACY_VIEW_OPTIONS

      expect(skeleton.fetch('view_options').keys.map(&:to_sym)).to eq(registered_view_options)
      expect(skeleton.fetch('search_panel_options').keys.map(&:to_sym))
        .to eq(described_class::SearchPanelOptions.configure_with_items)
      expect(skeleton.fetch('embedded_options').keys.map(&:to_sym))
        .to eq(described_class::EmbeddedOptions.configure_with_items)
      expect(skeleton.fetch('view_options').keys.map(&:to_sym) & described_class::LEGACY_VIEW_OPTIONS).to be_empty
      expect(skeleton.values.flat_map(&:values).compact).to be_empty
      expect(skeleton_text).to include('# shared view_options', '# report page view_options')
    end

    it 'makes a report with all-null options validate and behave like empty options' do
      skeleton = described_class.new_report_options_skeleton
      empty_report = report_with_options(nil)
      skeleton_report = report_with_options(skeleton)

      expect(empty_report).to be_valid
      expect(skeleton_report).to be_valid
      %i[view_options search_panel_options embedded_options].each do |context|
        expect(skeleton_report.report_options.public_send(context).to_h)
          .to eq(empty_report.report_options.public_send(context).to_h)
      end
    end
  end

  describe 'option definition documentation' do
    it 'documents every registered option block and key' do
      definitions = Rails.root.join('app/models/admin/defs/report_options_defs.yaml').read
      registered_blocks_and_keys = described_class.option_types[:multi].flat_map do |block|
        configuration = described_class.const_get(block.to_s.camelize)
        [block.to_s, *configuration.configure_with_items.map(&:to_s)]
      end

      expect(registered_blocks_and_keys.reject { |key| definitions.include?(key) }).to be_empty
    end
  end

  private

  def build_options(configuration)
    report = Report.new(options: configuration.deep_stringify_keys.to_yaml)
    described_class.new(report)
  end

  def report_with_options(options)
    Report.new(
      name: "Issue 1522 all-null options #{SecureRandom.hex(4)}",
      sql: 'select 1 as result_value',
      report_type: 'report',
      search_attrs: '',
      options:,
      disabled: false,
      current_admin: Admin.first
    )
  end
end
