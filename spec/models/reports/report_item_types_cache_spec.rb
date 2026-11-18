# frozen_string_literal: true

# Purpose: verify report and general-selection item-type caches invalidate after report changes.

require 'rails_helper'

RSpec.describe Report, type: :model do
  include ModelSupport
  include ReportSupport

  before do
    create_admin
    create_user
    create_reports
    @editable_report = @report1
    @editable_report.update!(edit_model: 'masters', selection_fields: 'previous_cache_field')
  end

  it 'rebuilds report item types after an editable report changes without clearing the cache' do
    Report.item_types(refresh: true)
    expected_type = report_item_type('updated_cache_field')

    update_report_selection_fields('updated_cache_field')

    expect(Report.item_types).to include(expected_type)
  end

  it 'rebuilds GeneralSelection item types after an editable report changes without clearing the cache' do
    Classification::GeneralSelection.item_types(refresh: true)
    expected_type = report_item_type('updated_general_selection_field')

    update_report_selection_fields('updated_general_selection_field')

    expect(Classification::GeneralSelection.item_types).to include(expected_type)
  end

  private

  def report_item_type(field_name)
    :"report_#{@editable_report.name.id_underscore}_#{field_name}"
  end

  def update_report_selection_fields(field_name)
    allow(@editable_report).to receive(:clear_rails_cache_on_save?).and_return(false)
    @editable_report.update!(selection_fields: field_name)
  end
end
