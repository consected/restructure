# frozen_string_literal: true

module ViewHandlers
  module Contact
    extend ActiveSupport::Concern

    included do
      validates :source, 'validates/source' => true, allow_blank: true
      validates :rank, presence: true
    end

    class_methods do
      # Add additional includes after this handler has been included
      def handle_include_extras
        include RankHandler
        include RecTypeHandler
      end

      # an informal key onto the table is the :data field
      def secondary_key
        :data
      end

      def category
        :subjects
      end
    end
  end
end
