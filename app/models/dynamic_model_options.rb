class DynamicModelOptions < ExtraOptions
  attr_accessor :caption_before

  protected

    def self.set_defaults config_obj, all_options={}
      all_options[:default] ||= {}
    end
end
