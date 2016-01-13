require 'rails_helper'

RSpec.describe Admin::CollegesController, type: :controller do

  include CollegeSupport
  
  def object_class
    College
  end
  
  def item
    @college
  end
  
  before(:all) do
    @path_prefix = "/admin"
    College.connection.execute "
      delete from college_history;
      delete from colleges;
    "
        
    Rails.cache.clear    
  end
  
  
  it_behaves_like 'a standard admin controller'
  
end
