# frozen_string_literal: true

class Admin::ReportsController < AdminController
  include DefinitionVersionsController

  SearchAttrBrowserCacheSeconds = 48.hours.to_i

  helper_method :embedded_report, :search_attrs_params_hash

  def self.local_prefixes
    super + ['reports']
  end

  def search_attr_definer
    cache_key = Digest::SHA256.hexdigest(helpers.partial_cache_key('report_search_attr_definer'))
    set_browser_cache(max_age: SearchAttrBrowserCacheSeconds)
    return unless stale?(etag: cache_key)

    render partial: 'admin/reports/form/search_attr_definer'
  end

  def preview
    @report = Report.find(params[:id])
    @report.current_user = current_user if current_user
    @runner = @report.runner
    @embedded_report = true
    @force_view_as = 'table'

    @runner.search_attr_values = search_attrs_params_hash
    @results = @runner.run(search_attrs_params_hash, current_admin)

    render partial: 'reports/results'
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
    { item_type: Report.categories.to_h { |g| [g, g.to_s] } }
  end

  def editor_code_type
    'sql'
  end

  def encode_options_fields
    { sql: :base64 }
  end

  private

  def permitted_params
    %i[id name item_type primary_table sql description disabled report_type auto searchable position search_attrs
       edit_model edit_field_names selection_fields short_name options]
  end

  def index_params
    %i[name item_type category report_type auto searchable admin_id]
  end

  attr_reader :embedded_report

  def search_attrs_params_hash
    # Plain Hash used only for report runner query parameter binding.
    # Use to_unsafe_h instead of permit! so the params object itself is
    # not marked permitted (avoiding any accidental mass-assignment).
    @search_attrs_params_hash ||= if params[:search_attrs].blank?
                                    { _use_defaults_: '_use_defaults_' }
                                  else
                                    params.require(:search_attrs).to_unsafe_h.dup
                                  end
  end
end
