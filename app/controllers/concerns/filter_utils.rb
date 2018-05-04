module FilterUtils

  extend ActiveSupport::Concern


  def filtered_primary_model pm=nil
    pm ||= primary_model
    if filter_params
      pm = pm.active if filter_params[:disabled] == 'enabled'
      pm = pm.disabled if filter_params[:disabled] == 'disabled'
      p = filter_params
      p.delete(:disabled)

      pm = pm.where(p).all
    end

    pm
  end

  def filter_defaults
  end

  def filter_params
    return @filter_params if @filter_params
    has_disabled_field = primary_model.attribute_names.include?('disabled')

    params[:filter] ||= filter_defaults

    if params[:filter].blank? || (params[:filter].is_a?( Array) && params[:filter][0].blank?)
      if has_disabled_field
        params[:filter] = {disabled: 'enabled'}
      else
        return
      end
    end
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
