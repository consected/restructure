# frozen_string_literal: true

module FilterUtils
  extend ActiveSupport::Concern

  #
  # Generate the results list for a controller index, filtering the
  # primary model using the `filter[]`` URL parameters
  # Special attributes:
  #   id: the id of a specific resource
  #   ids: an array of ids for matching resources, as `filter[ids][]=`
  #   filter_name: lookup by resource name, even if this isn't a database attribute
  # If a value ends with a '%' then we assume a LIKE is required to filter
  # If a value is "is not null" or "is null" then specifically handle that
  # @param [ActiveRecord::Model] pm optionally overrides the default in the primary_model attribute value
  # @return [ActiveRecord::Relation] <description>
  def filtered_primary_model(pm = nil)
    pm ||= primary_model

    if filter_params
      pm = pm.active if filter_params[:disabled] == 'enabled' || !current_admin
      pm = pm.disabled if filter_params[:disabled] == 'disabled' && current_admin
      filter_params[:id] ||= filter_params.delete(:ids) if filter_params[:ids].present?
      p = filter_params
      p.delete(:disabled)
      p.delete(:failed)
      p.delete(:ids)
      filter_name = p.delete(:filter_name)

      likes = ['']
      p.each do |k, v|
        next unless v.is_a? String

        # Handle likes and nulls
        if v&.end_with?('%')
          likes[0] += ' AND ' if likes.length > 1
          likes[0] += "#{k} LIKE ?"
          likes << v
          p.delete(k)
        elsif v&.index(/is (not )?null/)
          likes[0] += "#{k} #{v}"
          p.delete(k)
        end
      end

      pm = pm.where(p)
      pm = pm.where(likes) if likes.present? && likes.first.present?

      # If we have a filter name specified, use it to prepare a list of ids using the #resource_name method,
      # then apply these ids to the filter result
      if filter_name.present?
        pm_ids = pm.all.select { |pi| pi.respond_to?(:resource_name) && pi.resource_name == filter_name }.map(&:id)
        pm = pm.where(id: pm_ids)
      end

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
    if app_type_id && primary_model_uses_app_type?
      f = filter_params_permitted && filter_params_permitted[:app_type_id]
      if f&.blank?
        {}
      elsif f.present?
        { app_type_id: f }
      else
        { app_type_id: app_type_id.to_s }
      end
    else
      {}
    end
  end

  #
  # Does the primary model have a *disabled* field in the database?
  def has_disabled_field
    primary_model.attribute_names.include?('disabled') && current_admin
  end

  #
  # Is the primary model tied directly to an app type with an app_type_id field?
  def primary_model_uses_app_type?
    primary_model.attribute_names.include?('app_type_id')
  end

  #
  # All the attributes that are permitted for filtering
  def filter_params_permitted
    return @filter_params_permitted if @filter_params_permitted

    fo = filters_on
    # Add some additional attributes to allow to be filtered on
    fo << :disabled if has_disabled_field
    fo << :id
    fo << { ids: [] }
    fo << :filter_name

    @filter_params_permitted = params.require(:filter).permit(fo) if params[:filter]
  end

  #
  # Allow the requested filter to be used as an array in controller and view code
  def filter_params_hash
    @filter_params_hash ||= filter_params_permitted&.to_h || {}
  end

  #
  # Clean up the `filter[]`` URL parameters, removing empty string values and
  # setting nils to 'IS NULL' in preparation for later querying
  # NOTE: Intentionally not memoized - this breaks things
  # @return [Hash] a hash that can safely be used in redirects and link_to
  def filter_params
    # Set up filter_params_permitted
    fpp = filter_params_permitted

    if has_disabled_field && (
        filter_params_permitted.blank? ||
        (filter_params_permitted.is_a?(Array) && filter_params_permitted[0].blank?)
      )

      fpp = { disabled: 'enabled' }
    end

    unless fpp
      @filter_params = {}
      return @filter_params
    end

    fpp[:disabled] ||= 'enabled' if has_disabled_field

    res = fpp || {}
    res = filter_defaults.merge(res)

    num_to_clear_ids = 1
    num_to_clear_ids += 1 if has_disabled_field
    num_to_clear_ids += 1 if primary_model_uses_app_type?

    if res.keys.length > num_to_clear_ids
      res.delete 'ids'
      res.delete 'id'
    end

    res.reject! { |_k, v| v.blank? }

    res.each do |k, v|
      res[k] = nil if v == 'IS NULL'
    end

    res.symbolize_keys!

    @filter_params = res
  end
end
