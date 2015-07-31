require 'rails_helper'

RSpec.describe ManageUsersController, type: :controller do

  #include ManageUserSupport
  
  def object_class
    ManageUser
  end
  def item
    @manage_user
  end

  
  
end
