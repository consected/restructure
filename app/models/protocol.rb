class Protocol < ActiveRecord::Base

  include SelectorCache
  belongs_to :user
  
end
