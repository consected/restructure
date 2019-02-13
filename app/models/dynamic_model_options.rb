class DynamicModelOptions < ExtraOptions
  # attr_accessor :caption_before, :fields

  protected

    def self.set_defaults config_obj, all_options={}
      all_options[:default] ||= {}
      all_options[:default][:fields] ||= config_obj.all_implementation_fields
    end
end
