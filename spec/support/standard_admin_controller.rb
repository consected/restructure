# frozen_string_literal: true

require 'set'
shared_examples 'a standard admin controller' do
  let(:valid_attributes) do
    valid_attribs
  end

  let(:list_invalid_attributes) do
    list_invalid_attribs
  end

  let(:list_invalid_update_attributes) do
    list_invalid__update_attribs
  end

  let(:invalid_attributes) do
    invalid_attribs
  end

  let(:invalid_update_attributes) do
    invalid_update_attribs
  end
  let(:path_prefix) do
    instance_var_init :path_prefix
    @path_prefix
  end

  let(:object_param_symbol) do
    object_class.name.underscore.gsub('/', '_')
  end

  describe 'Ensure authentication' do
    before_each_login_admin
    it 'returns a result' do
      get :index
      expect(response).to have_http_status(200), "Attempting #{@admin} - got response code #{response.status}"
    end
  end

  describe 'GET #index' do
    before_each_login_admin

    it 'assigns all items as @vars' do
      create_items

      # Get all items, active or disabled
      get :index, params: { filter: { disabled: nil } }

      # Do this, since we can't guarantee the order of any particular controller response
      @created_items.each do |ci|
        expect(assigns(objects_symbol)).to include(ci), "Failed to get created items. #{@exceptions}"
      end
    end
  end

  describe 'GET #show' do
    before_each_login_admin

    it 'assigns the requested item as @var' do
      create_item

      expect_to_be_bad_route(get: "#{path_prefix}/#{object_symbol}/#{item_id}")
    end
  end

  describe 'GET #new' do
    before_each_login_admin

    it 'assigns a new item as @var' do
      get :new
      expect(assigns(object_symbol)).to be_a_new(object_class)
    end
  end

  describe 'GET #edit' do
    before_each_login_admin
    it 'assigns the requested item as @var' do
      create_item
      get :edit, params: { id: item_id }
      expect(assigns(object_symbol)).to eq(item)
      expect(response).to render_template(edit_form_admin)
    end
  end

  describe 'POST #create' do
    before_each_login_admin
    context 'with valid params' do
      it 'creates a new item' do
        va = valid_attributes
        os = object_param_symbol
        expect do
          post :create, params: { os => va }
        end.to change(object_class, :count).by(1), "#{os} was not created with valid attributes #{va}. "
      end

      it 'assigns a newly created item as @var' do
        post :create, params: { object_param_symbol => valid_attributes }
        expect(assigns(object_symbol)).to be_a(object_class)
        expect(assigns(object_symbol)).to be_persisted,
                                          "#{object_symbol} was not persisted. #{assigns(object_symbol).errors.to_a.join(' ')}"
      end

      it 'return success' do
        va = valid_attributes
        post :create, params: { object_param_symbol => va }
        expect(response).to render_template(saved_item_template),
                            "Incorrect response from create #{object_symbol} with #{va} (#{response}). Expected render template #{saved_item_template}.  #{assigns(object_symbol).errors.to_a.join("\n")}"
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved item as @var' do
        post :create, params: { object_param_symbol => invalid_attributes }
        expect(assigns(object_symbol)).to be_a_new(object_class)
      end

      it "re-renders the 'form' template" do
        list_invalid_attributes.each do |inv|
          post :create, params: { object_param_symbol => inv }
          expect(response).to render_template(edit_form_admin)
        end
      end
    end
  end

  describe 'PUT #update' do
    before_each_login_admin
    context 'with valid params' do
      let(:new_attributes) do
        new_attribs
      end

      it 'updates the requested item' do
        create_item
        put :update, params: { :id => item_id, object_param_symbol => new_attributes }
        item.reload
        new_attribs_downcase.each do |k, att|
          expect(item.send(k)).to eq att
        end
      end

      it 'assigns the requested item as @var' do
        create_item
        put :update, params: { :id => item_id, object_param_symbol => new_attributes }
        expect(assigns(object_symbol)).to eq item
      end

      it 'render the index' do
        create_item
        put :update, params: { id: item_id, object_param_symbol => new_attributes }
        expect(flash[:warning]).to_not be_present
        expect(response).to render_template(saved_item_template)
      end
    end

    context 'with invalid params' do
      it 'assigns the item as @var' do
        create_item
        ia = invalid_update_attributes
        put :update, params: { :id => item_id, object_param_symbol => ia }
        expect(flash[:warning]).to be_present, "No error was reported when assigning with invalid params: #{ia}"
        expect(assigns(object_symbol)).to eq(item)
      end

      it "re-renders the 'edit' template" do
        create_item
        put :update, params: { :id => item_id, object_param_symbol => invalid_update_attributes }

        expect(response).to render_template(edit_form_admin) # , "Rendered incorrect template with invalid_update_attributes: #{invalid_update_attributes.inspect}"
      end
    end
  end

  describe 'DELETE #destroy' do
    before_each_login_admin
    it 'never destroys the requested item' do
      create_item
      expect_to_be_bad_route(delete: "#{path_prefix}/#{object_symbol}/#{item_id}")
      #      delete :destroy, {:id => item_id}
      #      expect(response).to have_http_status(401)
    end
  end
end
