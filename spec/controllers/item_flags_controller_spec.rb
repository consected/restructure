# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemFlagsController, type: :controller do
  include ItemFlagSupport

  def object_class
    ItemFlag
  end

  def item
    @item_flag = nil unless defined? @item_flag
    @item_flag
  end

  let(:valid_attributes) do
    valid_attribs
  end

  let(:list_invalid_attributes) do
    list_invalid_attribs
  end

  let(:invalid_attributes) do
    invalid_attribs
  end

  describe 'Ensure authentication' do
    before_each_login_user
    before_each_login_admin
    it 'returns a result' do
      create_item

      get :index, params: { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id }
      expect(response).to have_http_status(200), "Attempting #{@user}"
    end
  end

  describe 'GET #index' do
    before_each_login_user
    before_each_login_admin

    it 'assigns all items as @vars' do
      create_items
      raise 'No item flag names specified' if Classification::ItemFlagName.active.empty?
      unless Classification::ItemFlagName.use_with_class_names.include?('player_info')
        raise 'Tests require player_info to have an item flag name'
      end

      get :index, params: { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id }
      expect(assigns(objects_symbol)).to include(item)
    end
  end

  describe 'GET #show' do
    before_each_login_user
    before_each_login_admin

    it 'assigns the requested item as @var' do
      create_item

      get :show, params: { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, id: item_id }
      expect(assigns(object_symbol)).to eq(item)
    end
  end

  describe 'GET #new' do
    before_each_login_user
    before_each_login_admin
    it 'allows new' do
      create_item
      attr = { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id }
      get :new, params: attr
      expect(response).to render_template '_edit_form'
    end
  end

  describe 'GET #edit' do
    before_each_login_user
    before_each_login_admin
    it 'prevents editing' do
      create_item
      attr = { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, id: item_id }

      u = "/masters/#{attr[:master_id]}/#{attr[:item_controller]}/#{attr[:item_id]}/item_flags/#{attr[:id]}/edit"
      expect_to_be_bad_route(get: u)
    end
  end

  describe 'POST #create' do
    before_each_login_user
    before_each_login_admin

    before :each do
      setup_access :player_infos
      setup_access :item_flags
    end
    context 'with valid params' do
      it 'creates a new item' do
        create_master
        create_item

        @player_info.item_flags.delete_all

        expect do
          attr = { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, item_flag: { item_flag_name_id: [@item_flag_name.id] } }
          post :create, params: attr
        end.to change(object_class, :count).by(1), "Didn't create a new item."
      end

      it 'assigns a newly created item as @var' do
        create_master
        va = valid_attributes
        attr = { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, item_flag: { item_flag_name_id: [@item_flag_name.id] } }
        post :create, params: attr

        expect(assigns(objects_symbol)).to be_a(@player_info.item_flags.class), "Item was not persisted with atts #{va.inspect}"
      end

      it 'returns success' do
        va = valid_attributes
        attr = { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, item_flag: { item_flag_name_id: [@item_flag_name.id] } }
        post :create, params: attr
        expect(response).to have_http_status(200), "Didn't get a 200 response with atts #{va.inspect}"
      end
    end

    context 'with invalid params' do
      it 'checks the item is valid' do
        create_item
        attr = { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: nil, item_flag: { item_flag_name_id: [@item_flag_name.id] } }
        expect { post :create, params: attr }.to raise_error ActionController::UrlGenerationError

        attr = {
          master_id: @player_info.master_id,
          item_controller: 'masters',
          item_id: @player_info.id,
          item_flag: {
            item_flag_name_id: [@item_flag_name]
          }
        }
        # expect { post :create, attr}.to raise_error ActionController::RoutingError
        post :create, params: attr
        expect(response).to have_http_status(404), "Didn't get a 404 response (got #{response.status}) with attr #{attr.inspect}"
      end

      it 'assigns a newly created but unsaved item as @var' do
        # ia = invalid_attributes

        expect(assigns(:item_flags)).to be_nil, "Create should not return a value: #{item}"
      end

      it "re-renders the 'new' template" do
        list_invalid_attributes.each do |inv|
          post :create, params: inv
          expect(response).to have_http_status(422), "expected #{response.status} to be 422 with data #{inv}"
          expect(flash[:danger]).to match('The request failed to validate')
        end
      end
    end
  end

  describe 'PUT #update' do
    before_each_login_user
    before_each_login_admin
    context 'with valid params' do
      let(:new_attributes) do
        new_attribs
      end

      it 'updates the requested item' do
        create_item

        attr = { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: @player_info.id, id: item_id }
        u = "/masters/#{attr[:master_id]}/#{attr[:item_controller]}/#{attr[:item_id]}/item_flags/#{attr[:id]}"
        expect_to_be_bad_route(patch: u)
      end
    end
  end

  describe 'DELETE #destroy' do
    before_each_login_user
    before_each_login_admin
    it 'never destroys the requested item' do
      create_item
      expect_to_be_bad_route(delete: "item_flags/#{item_id}")
      expect_to_be_bad_route(delete: "masters/1/player_infos/2/item_flags/#{item_id}")
      # delete :destroy, {:id => item_id, master_id: @master_id}
      # expect(response).to have_http_status(401)
    end
  end

  describe 'show that Brakeman security warning is not an issue' do
    before_each_login_user
    before_each_login_admin
    it 'attempts to force use of an invalid definition type' do
      create_item

      expect { get :index, params: { master_id: @player_info.master_id, item_controller: 'player_infos', item_id: 'item_id' } }
      expect(response).to be_successful
      get :index, params: { master_id: @player_info.master_id, item_controller: 'masters', item_id: 'item_id' }
      expect(response).to have_http_status 404

      get :index, params: { master_id: @player_info.master_id, item_controller: '&addresses', item_id: 'item_id' }
      expect(response).to have_http_status 404
      get :index, params: { master_id: @player_info.master_id, item_controller: '12312', item_id: 'item_id' }
      expect(response).to have_http_status 404
      get :index, params: { master_id: @player_info.master_id, item_controller: 'nil_class', item_id: 'item_id' }
      expect(response).to have_http_status 404
    end
  end
end
