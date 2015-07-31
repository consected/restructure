require 'rails_helper'

RSpec.describe ItemFlagNamesController, type: :controller do

  include ItemFlagNameSupport
  
  def object_class
    ItemFlagName
  end
  def item
    @item_flag_name
  end

  it_behaves_like 'a standard admin controller'
  
end
