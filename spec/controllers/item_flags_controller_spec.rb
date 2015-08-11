require 'rails_helper'

RSpec.describe ItemFlagsController, type: :controller do

  include ItemFlagSupport
  
  def object_class
    ItemFlag
  end
  def item
    @item_flag
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
    before_each_login_admin
    it "returns a result" do      
      
      create_item
      
      get :index, {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id}
      expect(response).to have_http_status(200), "Attempting #{@user}"
    end
  end
  
  describe "GET #index" do
    before_each_login_user
    before_each_login_admin 
    it "assigns all items as @vars" do      
      create_items
      
      get :index, {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id}
      expect(assigns(objects_symbol)).to eq([item])
    end
  end

  describe "GET #show" do
    before_each_login_user
    before_each_login_admin
    
    it "assigns the requested item as @var" do
      create_item
  
      get :show, {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id,  id: item_id}
      expect(assigns(object_symbol)).to eq(item)
    end
  end

  describe "GET #new" do
    before_each_login_user
    before_each_login_admin
    it "allows new" do
      create_item
      attr = {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id}
      get :new, attr 
      expect(response).to render_template '_edit_form'
      
    end
  end

  describe "GET #edit" do
    before_each_login_user
    before_each_login_admin
    it "prevents editing" do
      create_item      
      attr = {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id,  id: item_id}
      expect(edit: attr).not_to be_routable
      expect(edit: {id: item_id}).not_to be_routable
    end
  end

  describe "POST #create" do
    before_each_login_user
    before_each_login_admin
    context "with valid params" do            
      
      it "creates a new item" do
        create_master
        create_item
        
        @player_info.item_flags.delete_all
        
        expect {
          attr = {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, item_flag: {item_flag_name_id: [@item_flag_name.id]} }
          post :create, attr
        }.to change(object_class, :count).by(1), "Didn't create a new item."
      end

      it "assigns a newly created item as @var" do
        create_master
        va = valid_attributes
        attr = {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, item_flag: {item_flag_name_id: [@item_flag_name.id]} }
        post :create, attr
        
        expect(assigns(objects_symbol)).to be_a(@player_info.item_flags.class), "Item was not persisted with atts #{va.inspect}"
        
      end

      it "return success" do
        
        va = valid_attributes
        attr = {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, item_flag: {item_flag_name_id: [@item_flag_name.id]} }
        post :create,  attr
        expect(response).to have_http_status(200), "Didn't get a 200 response with atts #{va.inspect}"
      end
    end

    context "with invalid params" do
      it "checks the item is valid" do
        create_item
        attr = {master_id: @player_info.master_id, item_controller: 'player_infos', item_id: nil, item_flag: {item_flag_name_id: [@item_flag_name.id]} }
        expect { post :create, attr}.to raise_error ActionController::UrlGenerationError
        
        attr = {
          master_id: @player_info.master_id, 
          item_controller: 'pro_infos', 
          item_id: @player_info.id, 
          item_flag: {
            item_flag_name_id: [@item_flag_name]
          }         
        }
        expect { post :create, attr}.to raise_error ActionController::RoutingError
      end
      
      
      it "assigns a newly created but unsaved item as @var" do
        
        ia = invalid_attributes        
                
        expect(assigns(:item_flags)).to be_nil, "Create should not return a value: #{@item_flags}"
      end

      it "re-renders the 'new' template" do
        list_invalid_attributes.each do |inv|
          
          post :create, inv
          expect(response).to have_http_status(422), "expected #{response.status} to be 422 with data #{inv}"          
          expect(response.body).to eq "The request failed to validate"
        end
      end
    end
  end

  describe "PUT #update" do
    before_each_login_user
    before_each_login_admin
    context "with valid params" do
      let(:new_attributes) {
        new_attribs
      }

      it "updates the requested item" do
        
        expect(update: {item_flag: new_attribs}).not_to be_routable
        
        
      end

      
    end

  end

  describe "DELETE #destroy" do
    before_each_login_user
    before_each_login_admin
    it "never destroys the requested item" do
      create_item
      expect(:delete => "item_flags/#{item_id}").not_to be_routable
      expect(:delete => "masters/1/player_infos/2/item_flags/#{item_id}").not_to be_routable
      #delete :destroy, {:id => item_id, master_id: @master_id}
      #expect(response).to have_http_status(401)
    end

    
  end  
  
end
