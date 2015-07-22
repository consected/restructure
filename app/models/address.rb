class Address < ActiveRecord::Base
  include UserHandler
  
  validates :zip, zip: true, allow_blank: true
  validates :source, source: true, allow_blank: true
  
end
