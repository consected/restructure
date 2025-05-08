# frozen_string_literal: true

class Admin::ReportsController < AdminController

  def search_attr_definer
    Rails.cache.fetch('report_search_attr_definer', expires_in: 1.hour) do
      @report = Report.new    
      url = url_for([:admin, @report])
      ActionController::Base.helpers.form_for(@report, url: url, remote: true) do |f|
        render partial: 'admin/reports/form/search_attr_definer', locals: {f: f}
      end
    end
  end

  protected
  def set_defaults
    @show_again_on_save = true
  end

  def default_index_order
    { updated_at: :desc }
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
