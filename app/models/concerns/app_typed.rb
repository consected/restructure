module AppTyped

  extend ActiveSupport::Concern

  included do
    belongs_to :app_type, class_name: 'Admin::AppType'
    validates :app_type, presence: true
  end

end
