require 'rails_helper'

RSpec.describe Admin::GeneralSelectionsController, type: :controller do

  include GeneralSelectionSupport
  
  def object_class
    GeneralSelection
  end
  def item
    @general_selection
  end
  
  before(:all) do    
    @path_prefix = "/admin"
  end  
  
  before(:all){
    connection = ActiveRecord::Base.connection
    connection.execute("delete from general_selection_history") 
    @path_prefix = "/admin"
    GeneralSelection.destroy_all
  }
  it_behaves_like 'a standard admin controller'
  

end
