# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ProtocolEventsController, type: :controller do
  include ProtocolEventSupport

  def object_class
    Classification::ProtocolEvent
  end

  def item
    @protocol_event
  end

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

  let(:object_param_symbol) do
    :classification_protocol_event
  end

  before(:example) do
    TrackerHistory.destroy_all
    Tracker.destroy_all
    Classification::Protocol.connection.execute "
      delete from protocol_event_history;
      delete from protocol_events;
      delete from sub_process_history;
      delete from sub_processes;
      delete from protocol_history;
      delete from protocols;
    "
  end

  before :each do
    admin, = ControllerMacros.create_admin
    @admin = admin

    p = Classification::Protocol.create! name: "Q#{rand 1000}", position: rand(10_000), disabled: false, current_admin: @admin
    p.sub_processes.create! name: 'P1 123', current_admin: @admin
    @protocol = Classification::Protocol.create! name: "QA#{rand 1000}", position: rand(10_000), disabled: false, current_admin: @admin
    @protocol.sub_processes.create! name: 'P2 123', current_admin: @admin
    @sub_process = @protocol.sub_processes.create! name: 'P2 313', current_admin: @admin
    @protocol.sub_processes.create! name: 'P2 ABC', current_admin: @admin
    p = Classification::Protocol.create! name: "QB#{rand 1000}", position: rand(10_000), disabled: false, current_admin: @admin
    p.sub_processes.create! name: 'P3 123', current_admin: @admin

    @protocol_id = @protocol.id
    @sub_process_id = @sub_process.id
  end

  describe 'Ensure authentication' do
    before_each_login_admin
    it 'returns a result' do
      get :index, params: { protocol_id: @protocol_id, sub_process_id: @sub_process_id }
      expect(response).to have_http_status(200), "Attempting #{@admin}"
    end
  end

  describe 'GET #index' do
    before_each_login_admin

    it 'assigns all items as @vars' do
      create_items

      get :index, params: { protocol_id: @protocol_id, sub_process_id: @sub_process_id }

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

      u = "/protocols/#{@protocol.id}/sub_processes/#{@sub_process.id}/protocol_events/#{@protocol_event.id}"
      expect_to_be_bad_route(get: u)
    end
  end

  describe 'GET #new' do
    before_each_login_admin

    it 'assigns a new item as @var' do
      get :new, params: { protocol_id: @protocol_id, sub_process_id: @sub_process_id }
      expect(assigns(object_symbol)).to be_a_new(object_class)
    end
  end

  describe 'GET #edit' do
    before_each_login_admin
    it 'assigns the requested item as @var' do
      create_item
      get :edit, params: { id: item_id, protocol_id: @protocol_id, sub_process_id: @sub_process_id }
      expect(assigns(object_symbol)).to eq(item)
      expect(response).to render_template(edit_form_admin)
    end
  end

  describe 'POST #create' do
    before_each_login_admin
    context 'with valid params' do
      it 'creates a new item' do
        expect do
          post :create, params: { object_param_symbol => valid_attributes }
        end.to change(object_class, :count).by(1)
      end

      it 'assigns a newly created item as @var' do
        post :create, params: { object_param_symbol => valid_attributes }
        expect(assigns(object_symbol)).to be_a(object_class)
        expect(assigns(object_symbol)).to be_persisted
      end

      it 'return success' do
        post :create, params: { object_param_symbol => valid_attributes }
        expect(response).to render_template('_index')
        # redirect_to "/protocols/#{@protocol_id}/sub_processes/#{@sub_process_id}/#{objects_symbol}"
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
          expect(response).to render_template('_form')
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

      it 'redirects to the index' do
        create_item
        put :update, params: { :id => item_id, object_param_symbol => new_attributes }
        expect(flash[:warning]).to_not be_present
        # expect(response).to redirect_to("/protocols/#{@protocol_id}/sub_processes/#{@sub_process_id}/#{objects_symbol}")
        expect(response).to render_template('_index')
      end
    end

    context 'with invalid params' do
      it 'assigns the item as @var' do
        create_item
        ia = invalid_update_attributes
        put :update,  params: { :id => item_id, object_param_symbol => ia }
        expect(flash[:warning]).to be_present, "No error was reported when assigning with invalid params: #{ia}"
        expect(assigns(object_symbol)).to eq(item)
      end

      it "re-renders the 'edit' template" do
        create_item
        put :update, params: { :id => item_id, object_param_symbol => invalid_update_attributes }

        expect(response).to render_template(edit_form_admin)
      end
    end
  end

  describe 'DELETE #destroy' do
    before_each_login_admin
    it 'never destroys the requested item' do
      create_item
      expect_to_be_bad_route(delete: "/protocols/#{@protocol_id}/sub_processes/#{@sub_process_id}/#{object_symbol}/#{item_id}")
      expect_to_be_bad_route(delete: "/protocol_events/#{item_id}")
      #      delete :destroy, {:id => item_id}
      #      expect(response).to have_http_status(401)
    end
  end
end
