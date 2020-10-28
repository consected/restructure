module UserBaseHelper

  def add_extra_params_to_add_item_link ref_type, ref_config
    # Show the 'add' reference item button
    if ref_config[:add_with]
      aw = ref_config[:add_with].reject {|k,v| k == :extra_log_type}
      awp = {}
      if aw.length > 0
        item_param = ref_type.to_s.gsub('__', '_')
        awp = {
          item_param => {
            "embedded_item" => aw
          }
        }
        awp[item_param].merge!(aw)
      end
      add_extra_params = {}
      elt = ref_config[:add_with][:extra_log_type]
      add_extra_params[:extra_log_type] = elt if elt
      add_extra_params.merge! awp
      if add_extra_params
        res = "&#{add_extra_params.to_query.gsub('%7B%7B', '{{').gsub('%7D%7D', '}}')}"
      end
    end
    res
  end

end
