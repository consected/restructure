# frozen_string_literal: true

module ViewHandlers
  module Rank
    extend ActiveSupport::Concern

    included do
      validates :rank, presence: true,
                       if: -> { respond_to?(:rank) },
                       unless: :ignore_configurable_valid_if
    end

    class_methods do
      def handle_include_extras
        # DynamicModelBase already includes RankHandler, so this inclusion is idempotent.
        include RankHandler
      end
    end
  end
end
