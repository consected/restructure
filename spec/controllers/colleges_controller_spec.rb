require 'rails_helper'

RSpec.describe CollegesController, type: :controller do

  include CollegeSupport
  
  ObjectClass = College
  
  def item
    @college
  end
  
  ObjectsSymbol = ObjectClass.to_s.underscore.pluralize.to_sym
  
  ObjectSymbol = ObjectClass.to_s.underscore.to_sym
  
  def item_id
    item.to_param
  end
  
  def edit_form
    "#{ObjectsSymbol}/edit"
  end
  
  before(:all) do
    College.destroy_all
    Rails.cache.clear
  end
  
  it_behaves_like 'a standard admin controller'
  
end
