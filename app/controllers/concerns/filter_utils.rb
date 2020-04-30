# frozen_string_literal: true

module FilterUtils
  extend ActiveSupport::Concern

  #
  # Generate the results list for a controller index, filtering the
  # primary model using the `filter[]`` URL parameters
  # @param [ActiveRecord::Model] pm optionally overrides the default in the primary_model attribute value
  # @return [ActiveRecord::Relation] <description>
  def filtered_primary_model(pm = nil)
    pm ||= primary_model
    if filter_params
      pm = pm.active if filter_params[:disabled] == 'enabled' || !current_admin
      pm = pm.disabled if filter_params[:disabled] == 'disabled' && current_admin
      p = filter_params
      p.delete(:disabled)

      likes = ['']
      p.each do |k, v|
        next unless v&.end_with?('%')

        likes[0] += ' AND ' if likes.length > 1
        likes[0] += "#{k} LIKE ?"
        likes << v
        p.delete(k)
      end

      pm = pm.where(p)
      pm = pm.where(likes) if likes.length > 1

      pm = pm.all
    end

    pm
  end

  #
  # Set defaults for filters, to be used by filtered pages when
  # no `filter[]` URL parameters are set
  # The current user's app_type will be applied if this is not set in the filter
  # This may be overridden by controllers to provide different defaults
  # @return [Hash]
  def filter_defaults
    app_type_id = current_user&.app_type_id
    if app_type_id
      f = params[:filter] && params[:filter][:app_type_id]
      if f.present?
        { app_type_id: f }
      else
        { app_type_id: app_type_id.to_s }
      end
    else
      {}
    end
  end

  #
  # Clean up the `filter[]`` URL parameters, removing empty string values and
  # setting nils to 'IS NULL' in preparation for later querying
  # @return [Hash] a hash that can safely be used in redirects and link_to
  def filter_params
    return @filter_params if @filter_params

    has_disabled_field = primary_model.attribute_names.include?('disabled') && current_admin

    if params[:filter].blank? || (params[:filter].is_a?(Array) && params[:filter][0].blank?)
      params[:filter] = { disabled: 'enabled' } if has_disabled_field
    end

    fo = filters_on
    fo << :disabled if has_disabled_field

    return {} unless params[:filter]

    res = params.require(:filter).permit(fo)
    res = filter_defaults.merge(res)

    res.reject! { |_k, v| v.blank? }

    res.each do |k, v|
      res[k] = nil if v == 'IS NULL'
    end

    @filter_params = res
  end
end
