class DynamicModelOptions < ExtraOptions
  def self.set_defaults config_obj, all_options={}
    all_options[:default] ||= {}
    all_options[:default][:fields] ||= config_obj.all_implementation_fields
  end

  def self.raise_bad_configs option_configs
    # None defined - override with real checks
    # @todo
  end
end
