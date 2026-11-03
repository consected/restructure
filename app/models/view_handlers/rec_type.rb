# frozen_string_literal: true

module ViewHandlers
  module RecType
    extend ActiveSupport::Concern

    included do
      validates :rec_type, inclusion: { in: ->(record) { record.class.valid_rec_types } },
                           allow_blank: true,
                           if: -> { respond_to?(:rec_type) && self.class.valid_rec_types.present? },
                           unless: :ignore_configurable_valid_if
    end

    class_methods do
      def handle_include_extras
        include RecTypeHandler if valid_rec_types
      end
    end
  end
end
