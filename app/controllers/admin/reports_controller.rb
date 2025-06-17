# frozen_string_literal: true

class Admin::ReportsController < AdminController
  SearchAttrBrowserCacheSeconds = 48.hours.to_i
  EncodingTokenBase64 = "<Base64Encoded>"
  before_action :handle_sql_encoding, only: [:create, :update]

  def search_attr_definer
    cache_key = Digest::SHA256.hexdigest(helpers.partial_cache_key('report_search_attr_definer'))
    response.headers['Cache-Control'] = "max-age=#{SearchAttrBrowserCacheSeconds}"
    response.headers.delete 'Expires'
    return unless stale?(etag: cache_key)

    render partial: 'admin/reports/form/search_attr_definer'
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

  #
  # On update or creates, check if the SQL field has been base64 encoded on the front end.
  # The EncodingTokenBase64 token will be prepended if this is the case.
  # The SQL field is then decoded and the token is removed, so that the report definition
  # can be saved in the original plain text format.
  # The rationale for this is to avoid WAFs blocking requests that appear to be SQL injection.
  def handle_sql_encoding
    sql = secure_params[:sql]
    return unless sql&.start_with?(EncodingTokenBase64)

    b64sql = sql.sub(EncodingTokenBase64, '')
    sql = Base64.decode64(b64sql)
    secure_params[:sql].sub!(/.*/, sql)
  end
end
