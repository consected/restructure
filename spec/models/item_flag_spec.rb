require 'rails_helper'

RSpec.describe ItemFlag, type: :model do
  include ModelSupport
  include ItemFlagSupport
  before(:all) do
    seed_database
    create_user
    
    create_items
  end
end
