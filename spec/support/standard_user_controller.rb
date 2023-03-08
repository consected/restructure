# frozen_string_literal: true

require 'set'
shared_examples 'a standard user controller' do
  include ::UserSupport

  let(:valid_attributes) do
    valid_attribs
  end

  let(:list_invalid_attributes) do
    list_invalid_attribs
  end

  let(:invalid_attributes) do
    invalid_attribs
  end

  before :example do
    # seed_database
    create_admin
    create_user
    setup_access :addresses
    setup_access :scantrons
    setup_access :player_contacts
    setup_access :player_infos, access: :edit

    unless @user.has_access_to? :read, :general, :app_type
      setup_access :app_type, access: :read, resource_type: :general
    end

    validate_scantron_setup
    expect(Classification::AccuracyScore.active.where(value: 881)).to exist
  end

  describe 'Ensure authentication' do
    before_each_login_user
    it 'returns a result' do
      res = create_master
      get :index, params: { master_id: res.id }
      expect(response).to have_http_status(200), "Attempting #{@user}"
    end
  end

  describe 'GET #index' do
    before_each_login_user

    it 'assigns all items as @vars' do
      create_items # creates a new master for each item

      get :index, params: { master_id: @master_id }
      expect(assigns(objects_symbol)).to eq([item])
    end
  end

  describe 'GET #show' do
    before_each_login_user

    it 'assigns the requested item as @var' do
      create_item

      get :show, params: { id: item_id, master_id: @master_id }
      expect(assigns(object_symbol)).to eq(item)
    end
  end

  describe 'GET #new' do
    before_each_login_user

    it 'assigns a new item as @var' do
      master_id = create_master.id
      get :new, params: { master_id: master_id }
      expect(assigns(object_symbol)).to be_a_new(object_class)
    end
  end

  describe 'GET #edit' do
    before_each_login_user
    it 'assigns the requested item as @var' do
      create_item
      get :edit, params: { id: item_id, master_id: @master_id }
      expect(assigns(object_symbol)).to eq(item)
      expect(response).to render_template(edit_form_user)
    end
  end

  describe 'POST #create' do
    before_each_login_user
    context 'with valid params' do
      it 'creates a new item' do
        create_master
        setup_access :player_contacts, user: @master.current_user
        va = valid_attributes
        expect do
          post :create, params: { object_symbol => va, master_id: @master_id }
        end.to change(object_class, :count).by(1), "Didn't create a new item: #{va.inspect}."
      end

      it 'assigns a newly created item as @var' do
        create_master
        setup_access :player_contacts, user: @master.current_user
        va = valid_attributes
        post :create, params: { object_symbol => va, master_id: @master_id }
        expect(assigns(object_symbol)).to be_a(object_class)
        expect(assigns(object_symbol)).to be_persisted, "Item was not persisted with atts #{va.inspect}"
      end

      it 'return success' do
        create_master
        setup_access :player_contacts, user: @master.current_user
        va = valid_attributes
        post :create, params: { object_symbol => va, master_id: @master_id }
        expect(response).to have_http_status(200), "Didn't get a 200 response with atts #{va.inspect}. Got #{response.status}"
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved item as @var' do
        create_master
        setup_access :player_contacts, user: @master.current_user
        ia = invalid_attributes
        post :create, params: { object_symbol => ia, master_id: @master_id }
        expect(assigns(object_symbol)).to be_a_new(object_class), "Create should have item with no id using attribs #{ia.inspect}"
      end

      it "re-renders the 'new' template" do
        list_invalid_attributes.each do |inv|
          create_master
          setup_access :player_contacts, user: @master.current_user
          post :create, params: { object_symbol => inv, master_id: @master_id }
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

  describe 'PUT #update' do
    before_each_login_user
    context 'with valid params' do
      let(:new_attributes) do
        new_attribs
      end

      it 'updates the requested item' do
        create_item
        put :update, params: { :id => item_id, object_symbol => new_attributes, master_id: @master_id }

        expect(response).to have_http_status(200), "Response was not good: #{response.body}"

        item.reload
        new_attribs_downcase.each do |k, att|
          val = item.send(k) || ''
          att ||= ''
          expect(val).to eq(att), "Expected #{item.attributes.inspect} to equal #{new_attribs_downcase}"
        end
      end

      it 'assigns the requested item as @var' do
        create_item
        put :update, params: { :id => item_id, object_symbol => valid_attributes, master_id: @master_id }
        expect(assigns(object_symbol)).to eq item
      end

      it 'return success' do
        create_item
        va = put_valid_attribs || valid_attributes

        put :update, params: { :id => item_id, object_symbol => va, master_id: @master_id }
        expect(response).to have_http_status(200), "Expected 200 status with attributes: #{va}. Got #{response.status}"
        expect(resp.length).to be > 0
        expect(resp).to have_key(object_symbol.to_s), "Expected response to have key #{object_symbol}. Response #{response.body}"
      end
    end

    context 'with invalid params' do
      it 'assigns the item as @var' do
        create_item
        put :update, params: { :id => item_id, object_symbol => invalid_attributes, master_id: @master_id }
        expect(assigns(object_symbol)).to eq(item)
      end

      it "re-renders the 'edit' template" do
        create_item
        put :update, params: { :id => item_id, object_symbol => invalid_attributes, master_id: @master_id }

        expect(resp.length).to be > 0

        io = invalid_attributes.keys.first.to_s

        i = io.gsub('_', ' ').downcase
        i_no_id = io.gsub('_id', '').downcase
        t = I18n.translate("models.#{i_no_id}")
        expect(resp[io] || resp[i] || resp[i_no_id] || resp[t]).not_to be_nil, "Expected key: #{i} or #{io}. Got #{resp}"
      end
    end
  end

  describe 'DELETE #destroy' do
    before_each_login_user
    it 'never destroys the requested item' do
      create_item
      expect_to_be_bad_route(delete: "#{object_symbol}/#{item_id}")
      # delete :destroy, {:id => item_id, master_id: @master_id}
      # expect(response).to have_http_status(401)
    end
  end
end
