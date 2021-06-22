module OptionConfigs
  class BaseNamedConfiguration < OptionConfigs::BaseOptions
    include OptionsHandler

    attr_accessor :owner, :use_hash_config

    def config_text
      return super unless owner

      owner.config_text
    end

    def config_text=(value)
      unless owner
        super
        return
      end

      owner.config_text = value
    end

    def persisted?
      return true unless owner

      owner.persisted?
    end
  end
end
