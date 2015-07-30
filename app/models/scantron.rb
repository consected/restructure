class Scantron < ActiveRecord::Base
  
  include UserHandler
  
  validates :scantron_id, presence: true,  numericality: { only_integer: true, greater_than: 0, less_than: 1000000 }
  
end
