class DynamicModelBase < UserBase

  self.abstract_class = true

  include RankHandler


  # Use the view_options.data_attribute configuration option if it has been set,
  # otherwise use the data attribute from the table (if it has been set)
  def data
    dopt = self.class.definition.default_options
    return unless dopt && dopt.view_options
    da = dopt.view_options[:data_attribute]

    if da
      return self.class.format_data_attribute da, self
    elsif attribute_names.include?('data')
      return attributes['data']
    end
  end

  def self.format_data_attribute attr_conf, obj
    attr_conf = [attr_conf] if attr_conf.is_a? String
    res = attr_conf.map {|i| obj.attribute_names.include?(i) ? obj.attributes[i] : i }
    return res.join(' ')
  end

end
