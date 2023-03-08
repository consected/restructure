# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ProInfosController, type: :controller do
  include ProInfoSupport
  def object_class
    ProInfo
  end

  def item
    @pro_info
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
    it 'returns a result' do
      res = create_master
      get :index, params: { master_id: res.id }
      expect(response).to have_http_status(200), "Attempting #{@user}"
    end
  end

  describe 'GET #index' do
    before_each_login_user

    it 'assigns all items as @vars' do
      create_items

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

    it 'prevents new' do
      master_id = create_master.id
      expect_to_be_bad_route(get: "/masters/#{master_id}/pro_infos/new")
    end
  end

  describe 'GET #edit' do
    before_each_login_user
    it 'prevents editing' do
      create_item
      expect_to_be_bad_route(get: "/masters/#{@master_id}/pro_infos/#{item_id}/edit")
    end
  end

  describe 'POST #create' do
    before_each_login_user
    context 'with valid params' do
      it 'prevents create' do
        create_master

        expect_to_be_bad_route(post: "/masters/#{@master_id}/pro_infos/")
      end
    end
  end

  describe 'PUT #update' do
    before_each_login_user
    context 'with valid params' do
      let(:new_attributes) do
        new_attribs
      end

      it 'prevents updates to the requested item' do
        create_item

        expect_to_be_bad_route(patch: "/masters/#{@master_id}/pro_infos/#{item_id}")
      end
    end
  end

  describe 'DELETE #destroy' do
    before_each_login_user
    it 'never destroys the requested item' do
      create_item
      expect_to_be_bad_route(delete: "/masters/#{@master_id}/pro_infos/#{item_id}")
    end
  end
end
