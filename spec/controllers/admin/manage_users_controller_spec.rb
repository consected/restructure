require 'rails_helper'

RSpec.describe Admin::ManageUsersController, type: :controller do

  include ManageUserSupport
  
  def object_class
    User
  end
  
  def object_name
    "manage_user"
  end
  
  
  def item
    @manage_user
  end
  
  def edit_form_admin
    '_form'
  end

  let(:valid_attributes) {
    valid_attribs
  }
  
  let(:list_invalid_attributes){
    list_invalid_attribs
  }

  let(:list_invalid_update_attributes){
    list_invalid__update_attribs
  }

  
  let(:invalid_attributes) {
    invalid_attribs
  }

  let(:invalid_update_attributes) {
    invalid_update_attribs
  }

  
  describe "Ensure authentication" do
    before_each_login_admin
    it "returns a result" do            
      get :index
      expect(response).to have_http_status(200), "Attempting #{@admin}"
    end
  end
  
  describe "GET #index" do
    before_each_login_admin
     
    it "assigns all users, included the newly created ones as @users" do      
      create_items
      
      get :index      
      @created_items.each do |ci|
        expect(assigns(:users)).to include(ci), "Failed to get created items. #{@exceptions}"
      end
      
      expect(assigns(:users).length).to eq User.all.length
      expect(response).to render_template 'index'
    end
  end

  describe "GET #show" do
    before_each_login_admin
    
    
    it "to not be routable" do
      create_item
        
      expect(show: {id: @manage_user.id}).not_to be_routable
    end
  end

  describe "GET #new" do
    before_each_login_admin
    
    it "assigns a new item as @var" do
      
      get :new
      expect(assigns(:user)).to be_a_new(object_class)
    end
  end

  describe "GET #edit" do
    before_each_login_admin
    it "assigns the requested item as @var" do
      create_item
      get :edit, {:id => item_id}
      expect(assigns(:user)).to eq(item)
      expect(response).to render_template(edit_form_admin)
    end
  end

  describe "POST #create" do
    before_each_login_admin
    context "with valid params" do            
      
      it "creates a new item" do
        
        expect {
          post :create, {:user => valid_attributes}
        }.to change(object_class, :count).by(1)
      end

      it "assigns a newly created item as @var" do
        
        post :create, {:user => valid_attributes}
        expect(assigns(:user)).to be_a(object_class)
        expect(assigns(:user)).to be_persisted
      end

      it "return success" do
        va = valid_attributes
        post :create, {:user => va}
        expect(response).to render_template '_index'
        expect(assigns(:user).email).to eq va[:email]
        expect(assigns(:user).new_password).to be_a String
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved item as @var" do
        
        post :create, {:user => invalid_attributes}
        expect(assigns(:user)).to be_a_new(object_class)
      end

      it "re-renders the 'form' template" do
        list_invalid_attributes.each do |inv|
          
          post :create, {:user => inv}
          expect(response).to render_template("_form")
        end
      end
    end
  end

  describe "PUT #update" do
    before_each_login_admin
    context "with valid params" do
      let(:new_attributes) {
        new_attribs
      }

      
      it "updates the requested item" do
        create_item
        put :update, {:id => item_id, :user => new_attributes}
        item.reload
        new_attribs_downcase.each do |k, att|
          expect(item.send(k)).to eq att
        end
      end

      it "assigns the requested item as @var" do
        create_item
        put :update, {:id => item_id, :user => new_attributes}
        expect(assigns(:user)).to eq item
      end

      it "redirects to the index" do
        create_item
        put :update, {:id => item_id, :user => new_attributes}
        expect(flash[:warning]).to_not be_present
        expect(response).to render_template '_index'
      end
    end

    context "with invalid params" do
      it "assigns the item as @var" do
        create_item
        put :update, {:id => item_id, :user => invalid_update_attributes}
        expect(flash[:warning]).to be_present
        expect(assigns(:user)).to eq(item)
      end

      it "re-renders the 'edit' template" do
        create_item
        put :update, {:id => item_id, :user => invalid_update_attributes}
        
        expect(response).to render_template(edit_form_admin)
      end
    end
    
    context "special actions" do
      it "disables the user" do
        create_item
        put :update, {:id => item_id, :user => {disabled: 'true'}}        
        expect(flash[:warning]).to_not be_present
        expect(assigns(:user)).to eq @manage_user
        expect(assigns(:user).disabled?).to be true
        
        expect(response).to render_template '_index'
      end
      
      it "generates a new password for the user" do
        create_item
        put :update, {:id => item_id, :gen_new_pw => '1', :user => {disabled: 'false'}}        
        expect(flash[:warning]).to_not be_present
        expect(assigns(:user)).to eq @manage_user
        expect(assigns(:user).new_password).not_to be nil
        
        expect(response).to render_template '_index'
      end
    end
    
  end

  describe "DELETE #destroy" do
    before_each_login_admin
    it "never destroys the requested item" do
      create_item
      expect(delete: {id: item_id} ).not_to be_routable
    end

    
  end  
  
end
