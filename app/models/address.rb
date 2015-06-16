class Address < ActiveRecord::Base
  include UserHandler
  
  Types = [primary: 'primary']

end
