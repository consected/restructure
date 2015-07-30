require 'set'
shared_examples 'a standard admin controller' do

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
     
    it "assigns all items as @vars" do      
      create_items
      
      get :index      
      expect(assigns(ObjectsSymbol)).to eq(@created_items), "Failed to get created items. #{@exceptions}"
    end
  end

  describe "GET #show" do
    before_each_login_admin
    
    
    it "assigns the requested item as @var" do
      create_item
  
      get :show, {:id => item_id}
      expect(assigns(ObjectSymbol)).to eq(item)
    end
  end

  describe "GET #new" do
    before_each_login_admin
    
    it "assigns a new item as @var" do
      
      get :new
      expect(assigns(ObjectSymbol)).to be_a_new(ObjectClass)
    end
  end

  describe "GET #edit" do
    before_each_login_admin
    it "assigns the requested item as @var" do
      create_item
      get :edit, {:id => item_id}
      expect(assigns(ObjectSymbol)).to eq(item)
      expect(response).to render_template(edit_form)
    end
  end

  describe "POST #create" do
    before_each_login_admin
    context "with valid params" do            
      
      it "creates a new item" do
        
        expect {
          post :create, {ObjectSymbol => valid_attributes}
        }.to change(ObjectClass, :count).by(1)
      end

      it "assigns a newly created item as @var" do
        
        post :create, {ObjectSymbol => valid_attributes}
        expect(assigns(ObjectSymbol)).to be_a(ObjectClass)
        expect(assigns(ObjectSymbol)).to be_persisted
      end

      it "return success" do
        
        post :create, {ObjectSymbol => valid_attributes}
        expect(response).to redirect_to "/#{ObjectsSymbol}"
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved item as @var" do
        
        post :create, {ObjectSymbol => invalid_attributes}
        expect(assigns(ObjectSymbol)).to be_a_new(ObjectClass)
      end

      it "re-renders the 'new' template" do
        list_invalid_attributes.each do |inv|
          
          post :create, {ObjectSymbol => inv}
          expect(response).to render_template("new")
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
        put :update, {:id => item_id, ObjectSymbol => new_attributes}
        item.reload
        new_attribs_downcase.each do |k, att|
          expect(item.send(k)).to eq att
        end
      end

      it "assigns the requested item as @var" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => new_attributes}
        expect(assigns(ObjectSymbol)).to eq item
      end

      it "redirects to the index" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => new_attributes}
        expect(flash[:warning]).to_not be_present
        expect(response).to redirect_to("/#{ObjectsSymbol}")
      end
    end

    context "with invalid params" do
      it "assigns the item as @var" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => invalid_update_attributes}
        expect(flash[:warning]).to be_present
        expect(assigns(ObjectSymbol)).to eq(item)
      end

      it "re-renders the 'edit' template" do
        create_item
        put :update, {:id => item_id, ObjectSymbol => invalid_update_attributes}
        
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    before_each_login_admin
    it "never destroys the requested item" do
      create_item
      delete :destroy, {:id => item_id}
      expect(response).to have_http_status(401)
    end

    
  end  
  
end
