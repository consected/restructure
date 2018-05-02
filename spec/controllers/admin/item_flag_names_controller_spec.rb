require 'rails_helper'

RSpec.describe Admin::ItemFlagNamesController, type: :controller do

  include ItemFlagNameSupport

  def object_class
    Admin::ItemFlagName
  end
  def item
    @item_flag_name
  end

  before(:all) do
    seed_database
    @path_prefix = "/admin"
  end

  it_behaves_like 'a standard admin controller'

end
