class ItemFlagName < ActiveRecord::Base
  include SelectorCache
  belongs_to :user
  
end
