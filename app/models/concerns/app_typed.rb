module AppTyped

  extend ActiveSupport::Concern

  included do
    belongs_to :app_type
    validates :app_type, presence: true
  end

end
