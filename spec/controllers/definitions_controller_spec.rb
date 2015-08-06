require 'rails_helper'

describe DefinitionsController, type: :controller do
  include ControllerMacros
  
  describe "when not authenticated" do
    it "should require user login" do
    
      get :show, {id: 'protocol_events'}
      expect(response).to have_http_status(302)
      expect(response).to redirect_to '/users/sign_in'
    end
  
  end
 
  describe "when authenticated" do
    before_each_login_user
    before(:each) do
      @definitions_controller = DefinitionsController.new
    end

    it "should get latest protocol_events" do

      get :show, {id: 'protocol_events'}

      expect(response).to have_http_status(:success)
      j = JSON.parse(response.body)
      expect(j).to be_a Array
      expect(j.length).to eq ProtocolEvent.enabled.length      
    end
    
    it "show not get an unexpected item" do
      
      
      expect{get :show, {id: 'new'}}.to raise_error(ActionController::RoutingError)
    end
  end
end

