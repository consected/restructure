# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityLog::PlayerContactPhonesController, type: :controller do
  include ActivityLogSupport
  include ModelSupport
  include MasterSupport

  def object_class
    ActivityLog
  end

  def item
    @activity_log = nil unless defined? @activity_log
    @activity_log
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

  before(:example) do
    # SetupHelper.setup_al_player_contact_phones

    # seed_database

    create_admin
    create_user
    create_master @user

    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone_primary, resource_type: :activity_log_type
  end

  # before :each do
  #
  # end

  describe 'Ensure authentication' do
    before_each_login_user
    before_each_login_admin
    it 'returns a result' do
      create_item

      get :index, params: { master_id: @player_contact.master_id, item_id: @player_contact.id }
      expect(response).to have_http_status(200) # , "Attempting #{@user}"
    end
  end

  describe 'GET #index' do
    before_each_login_user
    before_each_login_admin
    it 'assigns all items as @vars' do
      create_items

      get :index, params: { master_id: item.master_id, item_id: @player_contact.id }

      expect(assigns(:activity_log__player_contact_phones).map(&:id)).to include(item.id)
    end
  end

  describe 'DELETE #destroy' do
    before_each_login_user
    before_each_login_admin
    it 'never destroys the requested item' do
      create_item
      expect_to_be_bad_route(delete: "activity_logs/#{item_id}")
      expect_to_be_bad_route(delete: "masters/1/player_contacts/2/activity_logs/#{item_id}")
      # delete :destroy, {:id => item_id, master_id: @master_id}
      # expect(response).to have_http_status(401)
    end
  end
end
