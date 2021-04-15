# frozen_string_literal: true

module OptionConfigs
  class PageLayoutOptions < BaseOptions
    def self.raise_bad_configs(_option_configs)
      # None defined - override with real checks
      # @todo
    end

    def self.attr_defs
      read_admin_defs 'page_layout_options_defs.yaml'
    end
  end
end
