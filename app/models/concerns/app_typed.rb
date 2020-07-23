# frozen_string_literal: true

module AppTyped
  extend ActiveSupport::Concern

  included do
    belongs_to :app_type, class_name: 'Admin::AppType', required: !app_type_not_required
    validates :app_type, presence: true unless app_type_not_required
  end

  class_methods do
    def app_type_not_required
      false
    end
  end
end
