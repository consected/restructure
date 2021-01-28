module OptionConfigs
  class BaseNamedConfiguration < OptionConfigs::BaseOptions
    include OptionsHandler

    attr_accessor :owner, :use_hash_config

    def persisted?
      owner&.persisted? || true
    end
  end
end
