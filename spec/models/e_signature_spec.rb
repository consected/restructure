require 'rails_helper'

Rspec.describe 'electronic signature of records', type: 'model' do

  include ModelSupport

  include ActivityLogSupport

  before :all do
    create_user
    create_master
    @al = create_item
  end

  describe "generate a text field containing data to be signed" do

    it "" do
      
    end

  end



end
