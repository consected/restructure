module NfsStore
  module Config
    class ExtraOptions

      def self.config_def if_extras: {}
        {
          pipeline: [
            {

            }
          ]
        }
      end

      def initialize config, item
        super
        @model_defs = config
      end


    end
  end
end
