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
      da = [da] if da.is_a? String
      res = da.map {|i| self.attributes[i]}
      return res.join(' ')
    elsif attribute_names.include?('data')
      return attributes['data']
    end
  end

end
