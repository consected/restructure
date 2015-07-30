require 'set'
shared_examples 'a standard user controller' do

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
      create_items # creates a new master for each item
      
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
    
    it "assigns a new item as @var" do
      master_id = create_master.id
      get :new, {master_id: master_id}
      expect(assigns(ObjectSymbol)).to be_a_new(ObjectClass)
    end
  end

  describe "GET #edit" do
    before_each_login_user
    it "assigns the requested item as @var" do
      create_item
      get :edit, {:id => item_id, master_id: @master_id}
      expect(assigns(ObjectSymbol)).to eq(item)
      expect(response).to render_template(edit_form)
    end
  end

  describe "POST #create" do
    before_each_login_user
    context "with valid params" do            
      
      it "creates a new item" do
        create_master
        expect {
          post :create, {ObjectSymbol => valid_attributes, master_id: @master_id}
        }.to change(ObjectClass, :count).by(1)
      end

      it "assigns a newly created item as @var" do
        create_master
        post :create, {ObjectSymbol => valid_attributes, master_id: @master_id}
        expect(assigns(ObjectSymbol)).to be_a(ObjectClass)
        expect(assigns(ObjectSymbol)).to be_persisted
      end

      it "return success" do
        create_master
        post :create, {ObjectSymbol => valid_attributes, master_id: @master_id}
        expect(response).to have_http_status 200
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved item as @var" do
        create_master
        post :create, {ObjectSymbol => invalid_attributes, master_id: @master_id}
        expect(assigns(ObjectSymbol)).to be_a_new(ObjectClass)
      end

      it "re-renders the 'new' template" do
        list_invalid_attributes.each do |inv|
          create_master
          post :create, {ObjectSymbol => inv, master_id: @master_id}
          expect(response).to have_http_status(422), "expected #{response.status} to be 422 with data #{inv}"
          expect(JSON.parse(response.body)).to have_key inv.keys.first.to_s
        end
      end
    end
  end

  describe "PUT #update" do
    before_each_login_user
    context "with valid params" do
      let(:new_attributes) {
        new_attribs
      }

      it "updates the requested item" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => new_attributes, master_id: @master_id}
        item.reload
        new_attribs_downcase.each do |k, att|
          expect(item.send(k)).to eq att
        end
      end

      it "assigns the requested item as @var" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => valid_attributes, master_id: @master_id}
        expect(assigns(ObjectSymbol)).to eq item
      end

      it "return success" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => valid_attributes, master_id: @master_id}
        expect(response).to have_http_status 200
        expect(resp.length).to be > 0
        expect(resp).to have_key ObjectSymbol.to_s
        
      end
    end

    context "with invalid params" do
      it "assigns the item as @var" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => invalid_attributes, master_id: @master_id}
        expect(assigns(ObjectSymbol)).to eq(item)
      end

      it "re-renders the 'edit' template" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => invalid_attributes, master_id: @master_id}
        
        expect(resp.length).to be > 0
        expect(resp).to have_key(invalid_attributes.keys.first.to_s), "Expected #{response.body} to have #{invalid_attributes.keys.first.to_s}"
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
