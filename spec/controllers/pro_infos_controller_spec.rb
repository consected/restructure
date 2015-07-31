require 'rails_helper'
RSpec.describe ProInfosController, type: :controller do

  include ProInfoSupport
  def object_class
    ProInfo
  end
  
  def item
    @pro_info
  end 
  
  let(:valid_attributes) {
    valid_attribs
  }
  
  let(:list_invalid_attributes){
    list_invalid_attribs
  }

  let(:invalid_attributes) {
    invalid_attribs
  }
  
  describe "Ensure authentication" do
    before_each_login_user
    it "returns a result" do      
      res = create_master
      get :index, {master_id: res.id}
      expect(response).to have_http_status(200), "Attempting #{@user}"
    end
  end
  
  describe "GET #index" do
    before_each_login_user
     
    it "assigns all items as @vars" do      
      create_items
      
      get :index, {master_id: @master_id}      
      expect(assigns(ObjectsSymbol)).to eq([item])
    end
  end

  describe "GET #show" do
    before_each_login_user
    
    
    it "assigns the requested item as @var" do
      create_item
  
      get :show, {:id => item_id, master_id: @master_id}
      expect(assigns(ObjectSymbol)).to eq(item)
    end
  end

  describe "GET #new" do
    before_each_login_user
    
    it "prevents new" do
      master_id = create_master.id
      get :new, {master_id: master_id}
      expect(response).to have_http_status :unauthorized
    end
  end

  describe "GET #edit" do
    before_each_login_user
    it "prevents editing" do
      create_item
      get :edit, {:id => item_id, master_id: @master_id}
      expect(response).to have_http_status :unauthorized

    end
  end

  describe "POST #create" do
    before_each_login_user
    context "with valid params" do            
      

      it "prevents create" do
        create_master
        post :create, {ObjectSymbol => valid_attributes, master_id: @master_id}
        expect(response).to have_http_status :unauthorized

      end      
    end

    context "with invalid params" do
      it "prevents create" do
        create_master
        post :create, {ObjectSymbol => invalid_attributes, master_id: @master_id}
        expect(response).to have_http_status :unauthorized

      end
      
    end
  end

  describe "PUT #update" do
    before_each_login_user
    context "with valid params" do
      let(:new_attributes) {
        new_attribs
      }

      it "prevents updates to the requested item" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => new_attributes, master_id: @master_id}
        expect(response).to have_http_status :unauthorized

      end

    end

    context "with invalid params" do
      it "prevents updates" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => invalid_attributes, master_id: @master_id}
        expect(response).to have_http_status :unauthorized

      end

    end
  end

  describe "DELETE #destroy" do
    before_each_login_user
    it "never destroys the requested item" do
      create_item
      delete :destroy, {:id => item_id, master_id: @master_id}
      expect(response).to have_http_status(401)
    end

    
  end  

  
end
