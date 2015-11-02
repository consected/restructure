require 'rails_helper'

RSpec.describe Admin::UserAuthorizationsController, type: :controller do

  include UserAuthorizationSupport
  
  def object_class
    UserAuthorization
  end
  def item
    @user_authorization
  end

  before(:each) do
    ControllerMacros.create_user
  end
  
  before(:all) do
    @edit_form_admin = 'admin/common_templates/_form' 
    @path_prefix = "/admin"
  end
  
  it_behaves_like 'a standard admin controller'
  

end

