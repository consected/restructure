# frozen_string_literal: true

# Specifies the new report type's context-aware buttons and auto-submit target.

require 'rails_helper'

RSpec.describe Reports::ButtonResolver, type: :model do
  describe 'default buttons by context' do
    it 'shows only the search-labeled list-records button in a search panel' do
      result = resolve_for(:search_panel)

      expect(button_values(result)).to eq(list_records: ['search', 'search'])
      expect(result.auto_submit_target).to eq(:list_records)
      expect(result.auto_submit_on_load?).to be(false)
      expect(result.auto_submit_on_change?).to be(false)
    end

    it 'renders a hidden list-records button, report button, and count button on a report page' do
      result = resolve_for(:report_page)

      expect(button_values(result)).to eq(
        list_records: ['list records', 'search'],
        report: ['report', 'table'],
        count: ['count', 'count']
      )
      expect(result.buttons[:list_records].hidden?).to be(true)
      expect(result.buttons[:report].hidden?).to be(false)
      expect(result.buttons[:count].hidden?).to be(false)
      expect(result.auto_submit_target).to eq(:report)
    end

    it 'renders only the report button in an embedded context' do
      result = resolve_for(:embedded)

      expect(button_values(result)).to eq(report: ['report', 'table'])
      expect(result.buttons[:list_records]).to be_nil
      expect(result.buttons[:count]).to be_nil
      expect(result.auto_submit_target).to eq(:report)
      expect(result.no_report_results_scroll?).to be(true)
    end
  end

  describe 'context labels and visibility options' do
    it 'applies search-panel label and hide options without removing the button' do
      result = resolve_for(
        :search_panel,
        search_panel_options: { search_records_button_label: 'Search records', hide_search_records_button: true }
      )
      button = result.buttons[:list_records]

      expect(button.label).to eq('Search records')
      expect(button.commit).to eq('search')
      expect(button.hidden?).to be(true)
    end

    it 'applies report-page labels, show-list, hide-report, and hide-count options independently' do
      result = resolve_for(
        :report_page,
        view_options: {
          report_button_label: 'Run report', list_records_button_label: 'List records',
          show_list_records_button: true, hide_report_button: true, hide_count_button: true,
          hide_result_count: true, no_report_results_scroll: true
        }
      )

      expect(button_values(result)).to eq(
        list_records: ['List records', 'search'], report: ['Run report', 'table'], count: ['count', 'count']
      )
      expect(result.buttons[:list_records].hidden?).to be(false)
      expect(result.buttons[:report].hidden?).to be(true)
      expect(result.buttons[:count].hidden?).to be(true)
      expect(result.hide_result_count?).to be(true)
      expect(result.no_report_results_scroll?).to be(true)
    end

    it 'applies embedded labels and hides the report button without removing it' do
      result = resolve_for(
        :embedded,
        embedded_options: { report_button_label: 'Run embedded report', hide_report_button: true }
      )
      button = result.buttons[:report]

      expect([button.label, button.commit, button.hidden?]).to eq(['Run embedded report', 'table', true])
    end

    it 'passes through export visibility for report-page actions' do
      result = resolve_for(:report_page, view_options: { hide_export_buttons: true })

      expect(result.hide_export_buttons?).to be(true)
    end

    it 'keeps count text visible when only the report-page count button is hidden' do
      result = resolve_for(:report_page, view_options: { hide_count_button: true })

      expect(result.buttons[:count].hidden?).to be(true)
      expect(result.hide_result_count?).to be(false)
    end

    it 'passes through search-panel result collapse options' do
      result = resolve_for(
        :search_panel,
        search_panel_options: { prevent_collapse_for_search_panel_results: true }
      )

      expect(result.prevent_collapse_for_search_panel_results?).to be(true)
    end
  end

  describe 'auto-submit classes and targets' do
    it 'adds auto-run and auto-submitter to the selected button in each context' do
      context_options = {
        search_panel: { search_panel_options: { auto_submit_on_load: true, auto_submit_on_change: true } },
        report_page: { view_options: { auto_submit_on_load: true, auto_submit_on_change: true } },
        embedded: { embedded_options: { auto_submit_on_load: true, auto_submit_on_change: true } }
      }
      expected_targets = { search_panel: :list_records, report_page: :report, embedded: :report }

      context_options.each do |context, options|
        result = resolve_for(context, **options)
        target_button = result.buttons.fetch(expected_targets.fetch(context))

        expect(result.auto_submit_target).to eq(expected_targets.fetch(context))
        expect(result.auto_submit_on_load?).to be(true)
        expect(result.auto_submit_on_change?).to be(true)
        expect(target_button.classes).to include('auto-run', 'auto-submitter')
      end
    end

    it 'forces auto-submit on load in every context without enabling change submission' do
      %i[search_panel report_page embedded].each do |context|
        result = resolve_for(context, force_run: true)
        target_button = result.buttons.fetch(result.auto_submit_target)

        expect(result.auto_submit_on_load?).to be(true)
        expect(result.auto_submit_on_change?).to be(false)
        expect(target_button.classes).to include('auto-run')
        expect(target_button.classes).not_to include('auto-submitter')
      end
    end

    it 'targets hidden list-records buttons when requested and never lets visibility block auto-submit' do
      result = resolve_for(
        :report_page,
        view_options: {
          hide_report_button: true, show_list_records_button: false,
          auto_submit_target: 'list_records', auto_submit_on_load: true, auto_submit_on_change: true
        }
      )
      button = result.buttons[:list_records]

      expect(result.auto_submit_target).to eq(:list_records)
      expect(button.hidden?).to be(true)
      expect(button.classes).to include('hidden', 'auto-run', 'auto-submitter')
    end

    it 'defaults the report-page target to list-records when the report button is hidden' do
      result = resolve_for(:report_page, view_options: { hide_report_button: true })

      expect(result.auto_submit_target).to eq(:list_records)
    end

    it 'allows the report-page target override to report despite a hidden report button' do
      result = resolve_for(
        :report_page,
        view_options: { hide_report_button: true, auto_submit_target: 'report', auto_submit_on_load: true }
      )

      expect(result.auto_submit_target).to eq(:report)
      expect(result.buttons[:report].classes).to include('hidden', 'auto-run')
    end

    it 'ignores the legacy auto flag for the new report type' do
      result = resolve_for(:report_page, report_auto: true)

      expect(result.auto_submit_on_load?).to be(false)
      expect(result.buttons[:report].classes).not_to include('auto-run')
    end
  end

  describe 'type isolation' do
    it 'ignores legacy button options for the new report type' do
      result = resolve_for(
        :report_page,
        view_options: {
          hide_search_button: true, hide_master_results_list_search_button: true,
          force_show_search_button: true, search_button_label: 'legacy',
          report_auto_submit_on_change: true, no_results_scroll: true,
          prevent_collapse_for_list: true
        }
      )

      expect(button_values(result)).to eq(
        list_records: ['list records', 'search'], report: ['report', 'table'], count: ['count', 'count']
      )
      expect(result.auto_submit_on_change?).to be(false)
      expect(result.no_report_results_scroll?).to be(false)
    end

    it 'returns no new-type button resolution for legacy report types' do
      %w[regular_report search count].each do |report_type|
        expect(resolve_for(:report_page, report_type:, view_options: { auto_submit_on_load: true })).to be_nil
      end
    end
  end

  private

  def resolve_for(context, report_type: 'report', report_auto: false, force_run: false,
                  view_options: {}, search_panel_options: {}, embedded_options: {})
    report = double('report', report_type:, auto: report_auto)
    options = { view_options:, search_panel_options:, embedded_options: }
    described_class.resolve(report:, context:, options:, force_run:)
  end

  def button_values(result)
    result.buttons.each_with_object({}) do |(key, button), values|
      values[key] = [button.label, button.commit] if button
    end
  end
end
