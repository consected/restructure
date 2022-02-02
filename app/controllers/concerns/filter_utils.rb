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
    init_pm = pm

    if filter_params
      pm = pm.active if filter_params[:disabled] == 'enabled' || !current_admin
      pm = pm.disabled if filter_params[:disabled] == 'disabled' && current_admin
      p = filter_params
      p.delete(:disabled)
      p.delete(:failed)

      likes = ['']
      p.each do |k, v|
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

      p[:allow_all_app_types] = true if init_pm == Admin::UserRole
      pm = pm.where(p)
      pm = pm.where(likes) if likes.length > 0 && likes.first.present?

      pm = pm.all
    end

    pm
  end

  def primary_model_uses_app_type?
    primary_model.attribute_names.include?('app_type_id')
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

  def has_disabled_field
    primary_model.attribute_names.include?('disabled') && current_admin
  end

  def filter_params_permitted
    return @filter_params_permitted if @filter_params_permitted

    fo = filters_on
    fo << :disabled if has_disabled_field

    @filter_params_permitted = params.require(:filter).permit(fo) if params[:filter]
  end

  def filter_params_hash
    @filter_params_hash ||= filter_params_permitted&.to_h || {}
  end

  #
  # Clean up the `filter[]`` URL parameters, removing empty string values and
  # setting nils to 'IS NULL' in preparation for later querying
  # @return [Hash] a hash that can safely be used in redirects and link_to
  def filter_params
    return @filter_params if @filter_params

    if (filter_params_permitted.blank? || (filter_params_permitted.is_a?(Array) && filter_params_permitted[0].blank?)) && has_disabled_field
      @filter_params_permitted = { disabled: 'enabled' }
    end

    unless @filter_params_permitted
      @filter_params = {}
      return @filter_params
    end

    res = @filter_params_permitted || {}
    res = filter_defaults.merge(res)

    res.reject! { |_k, v| v.blank? }

    res.each do |k, v|
      res[k] = nil if v == 'IS NULL'
    end

    res.symbolize_keys!

    @filter_params = res
  end
end
