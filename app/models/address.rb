class Address < ActiveRecord::Base
  include UserHandler
  
  validates :zip, zip: true
  validates :source, source: true
  
end
