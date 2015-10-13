class ExternalLink < ActiveRecord::Base
  include AdminHandler
  include SelectorCache
    
  validates :name, presence: true
end
