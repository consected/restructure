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
    res = College.delete_all
        
    Rails.cache.clear    
  end
  
  
  it_behaves_like 'a standard admin controller'
  
end
