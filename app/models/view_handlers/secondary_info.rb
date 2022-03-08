# frozen_string_literal: true

module ViewHandlers
  module SecondaryInfo
    extend ActiveSupport::Concern

    included do
    end

    class_methods do
      def category
        :subjects
      end
    end
  end
end
