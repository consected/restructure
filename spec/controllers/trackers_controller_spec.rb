require 'rails_helper'


RSpec.describe TrackersController, type: :controller do

  include TrackerSupport
  
  def item
    @tracker
  end
  
  def object_class
    Tracker
  end  
  
  before :each do    
    admin, pw = ControllerMacros.create_admin    
    @admin = admin
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
  
  
  ##### This follows the standard_user_controller model, except for create and update #######
  
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
      create_items # creates a new master for each item
      
      get :index, {master_id: @master_id}      
      expect(assigns(objects_symbol)).to eq([item])
    end
  end

  describe "GET #show" do
    before_each_login_user
    
    
    it "assigns the requested item as @var" do
      create_item
  
      get :show, {:id => item_id, master_id: @master_id}
      expect(assigns(object_symbol)).to eq(item)
    end
  end

  describe "GET #new" do
    before_each_login_user
    
    it "assigns a new item as @var" do
      master_id = create_master.id
      get :new, {master_id: master_id}
      expect(assigns(object_symbol)).to be_a_new(object_class)
    end
  end

  describe "GET #edit" do
    before_each_login_user
    it "assigns the requested item as @var" do
      create_item
      get :edit, {:id => item_id, master_id: @master_id}
      expect(assigns(object_symbol)).to eq(item)
      expect(response).to render_template(edit_form_user)
    end
  end

  describe "POST #create" do
    before_each_login_user
    context "with valid params" do            
      
      it "creates a new item" do
        create_master
        va = valid_attributes
        expect {
          
          post :create, {object_symbol => va, master_id: @master_id}
        }.to change(object_class, :count).by(1), "Didn't create a new item: #{va.inspect}."
      end

      it "assigns a newly created item as @var" do
        create_master
        va = valid_attributes
        post :create, {object_symbol => va, master_id: @master_id}
        expect(assigns(object_symbol)).to be_a(object_class)
        expect(assigns(object_symbol)).to be_persisted, "Item was not persisted with atts #{va.inspect}"
      end

      it "return success" do
        create_master
        va = valid_attributes
        post :create, {object_symbol => va, master_id: @master_id}
        expect(response).to have_http_status(200), "Didn't get a 200 response with atts #{va.inspect}"
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved item as @var" do
        create_master
        ia = invalid_attributes
        post :create, {object_symbol => ia, master_id: @master_id}
        expect(assigns(object_symbol)).to be_a_new(object_class), "Create should have item with no id using attribs #{ia.inspect}"
      end

      it "re-renders the 'new' template" do
        list_invalid_attributes.each do |inv|
          create_master
          post :create, {object_symbol => inv, master_id: @master_id}
          expect(response).to have_http_status(422), "expected #{response.status} to be 422 with data #{inv}"
          j = JSON.parse(response.body)
          io = inv.keys.first.to_s
          i = io.gsub('_', ' ').downcase
          i_no_id = io.gsub('_id', '').downcase
          t = I18n.translate("models.#{i_no_id}")
          expect(j[io] || j[i] || j[i_no_id] || j[t]).not_to be_nil, "Expected key: #{i} or #{io}. Got #{j}"
        end
      end
    end
  end

  ### This diverges from a standard controller, instead returning the latest item, not the most recently added   #####
  
  describe "PUT #update" do
    before_each_login_user
    context "with valid params" do
      let(:new_attributes) {
        new_attribs
      }

      it "updates the requested item as a new item" do
        create_item

        # Create an item far in the future so it appears at the top of the list
        new_attributes[:event_date] = (Date.today + 1.year).to_s
        
                
        put :update, {:id => item_id, object_symbol => new_attributes, master_id: @master_id}
        
        expect(response).to have_http_status(200), "Response was not good: #{response.body}"

                
        new_item = Tracker.find_by_master_id_and_protocol_id item.master_id, item.protocol_id
                        
        new_attribs_downcase.each do |k, att|
          expect(new_item.send(k)).to eq(att), "Expected #{new_item.attributes.inspect} to equal #{new_attribs_downcase} " 
        end
      end

      it "assigns the requested item as @var" do
        create_item
        
         # Create an item far in the future so it appears at the top of the list
        valid_attributes[:event_date] = (Date.today + 1.year).to_s
        
        put :update, {:id => item_id, object_symbol => valid_attributes, master_id: @master_id}
        
        new_item = Tracker.find_by_master_id_and_protocol_id @master_id, valid_attributes[:protocol_id]
        
        expect(assigns(object_symbol)).to eq new_item
      end

      it "return success" do
        create_item
        va = put_valid_attribs || valid_attributes
        
        put :update, {:id => item_id, object_symbol => va, master_id: @master_id}
        expect(response).to have_http_status(200), "Expected 200 status with attributes: #{va}"
        expect(resp.length).to be > 0
        expect(resp).to have_key object_symbol.to_s
        
      end
    end

    context "with invalid params" do
      it "assigns the item as @var" do
        create_item
        put :update, {:id => item_id, object_symbol => invalid_attributes, master_id: @master_id}
        expect(assigns(object_symbol)).to eq(item)
      end

      it "re-renders the 'edit' template" do
        create_item
        put :update, {:id => item_id, object_symbol => {protocol_id: 1000000}, master_id: @master_id}
        
        expect(resp.length).to be > 0
        
        io = invalid_attributes.keys.first.to_s
        
        i = io.gsub('_', ' ').downcase
        i_no_id = io.gsub('_id', '').downcase
        t = I18n.translate("models.#{i_no_id}")
        expect(resp[io] || resp[i] || resp[i_no_id] || resp[t]).not_to be_nil, "Expected key: #{i} or #{io}. Got #{resp}"
      end
    end
  end

  describe "DELETE #destroy" do
    before_each_login_user
    it "never destroys the requested item" do
      create_item
      expect(:delete => "#{object_symbol}/#{item_id}").not_to be_routable
      #delete :destroy, {:id => item_id, master_id: @master_id}
      #expect(response).to have_http_status(401)
    end

    
  end  

end
