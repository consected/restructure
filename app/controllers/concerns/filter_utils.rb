module FilterUtils

  extend ActiveSupport::Concern


  def filtered_primary_model pm=nil
    pm ||= primary_model
    if filter_params
      pm = pm.active if filter_params[:disabled] == 'enabled' || !current_admin
      pm = pm.disabled if filter_params[:disabled] == 'disabled' && current_admin
      p = filter_params
      p.delete(:disabled)

      likes = [""]
      p.each do |k,v|
        if v && v.end_with?('%')
          likes[0] << ' AND ' if likes.length > 1
          likes[0] << "#{k} LIKE ?"
          likes << v
          p.delete(k)
        end
      end

      pm = pm.where(p)
      pm = pm.where(likes) if likes.length > 1

      pm = pm.all
    end

    pm
  end

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

  def filter_params
    return @filter_params if @filter_params
    has_disabled_field = primary_model.attribute_names.include?('disabled') && current_admin


    if params[:filter].blank? || (params[:filter].is_a?( Array) && params[:filter][0].blank?)
      if has_disabled_field
        params[:filter] = {disabled: 'enabled'}
      end
    end

    params[:filter] ||= {}

    params[:filter] = filter_defaults.merge(params[:filter])

    fo = filters_on
    fo << :disabled if has_disabled_field
    res = params.require(:filter).permit(fo)

    res.reject! {|k,v| v.blank?}

    res.each do |k, v|
      res[k] = nil if v == 'IS NULL'
    end


    @filter_params = res
  end

end
