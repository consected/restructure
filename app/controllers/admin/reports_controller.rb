# frozen_string_literal: true

class Admin::ReportsController < AdminController
  protected

  def default_index_order
    Arel.sql 'disabled asc nulls first, updated_at desc'
  end

  def filters_on
    [:item_type]
  end

  def filters
    { item_type: Report.categories.map { |g| [g, g.to_s] }.to_h }
  end

  def editor_code_type
    'sql'
  end

  private

  def permitted_params
    %i[id name item_type primary_table sql description disabled report_type auto searchable position search_attrs
       edit_model edit_field_names selection_fields short_name options]
  end
end
