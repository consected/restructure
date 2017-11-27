require 'rails_helper'

# Ensure that we seed the database, otherwise the PlayerContactPhonesController class does not exist
RSpec.configure {|c| c.before {
  SeedSupport.setup
  }}

RSpec.describe ActivityLog::PlayerContactPhonesController, type: :controller do

  include ActivityLogSupport
  include ModelSupport
  include MasterSupport

  def object_class
    ActivityLog
  end
  def item
    unless defined? @activity_log
      @activity_log = nil
    end
    @activity_log
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

  before(:all) do

    seed_database

    create_admin
    create_user
    create_master @user


    if ActivityLog.connection.table_exists? "activity_log_player_contact_phones"
      sql = TableGenerators.activity_logs_table('activity_log_player_contact_phones', 'player_contacts', :drop_do)
    end

    TableGenerators.activity_logs_table('activity_log_player_contact_phones', 'player_contacts', true, 'select_result', 'select_next_step', 'follow_up_when', 'protocol_id', 'select_call_direction', 'select_who', 'called_when', 'notes', 'data', 'set_related_player_contact_rank')


  end

  # before :each do
  #   seed_database
  # end

  describe "Ensure authentication" do
    before_each_login_user
    before_each_login_admin
    it "returns a result" do

      create_item

      get :index, {master_id: @player_contact.master_id, item_id: @player_contact.id}
      expect(response).to have_http_status(200)#, "Attempting #{@user}"
    end
  end

  describe "GET #index" do
    before_each_login_user
    before_each_login_admin
    it "assigns all items as @vars" do

      create_items

      get :index, {master_id: item.master_id, item_id: @player_contact.id}

      expect(assigns(:activity_log__player_contact_phones)).to eq([item])
    end
  end

#   describe "GET #show" do
#     before_each_login_user
#     before_each_login_admin
#
#     it "assigns the requested item as @var" do
#       create_item
#       get :show, {master_id: @player_contact.master_id, item_id: @player_contact.id,  id: item_id}
#       expect(assigns(:item)).to eq(item)
#     end
#   end

#  describe "GET #new" do
#    before_each_login_user
#    before_each_login_admin
#    it "allows new" do
#      create_item
#      attr = {master_id: @player_contact.master_id, item_controller: 'player_contacts', item_id: @player_contact.id}
#      get :new, attr
#      expect(response).to render_template '_edit_form'
#
#    end
#  end

#  describe "GET #edit" do
#    before_each_login_user
#    before_each_login_admin
#    it "prevents editing" do
#      create_item
#      attr = {master_id: @player_contact.master_id, item_controller: 'player_contacts', item_id: @player_contact.id,  id: item_id}
#
#      u = "/masters/#{attr[:master_id]}/#{attr[:item_controller]}/#{attr[:item_id]}/activity_logs/#{attr[:id]}/edit"
#      expect(get: u).to_not be_routable
#    end
#  end
#
#  describe "POST #create" do
#    before_each_login_user
#    before_each_login_admin
#    context "with valid params" do
#
#      it "creates a new item" do
#        create_master
#        create_item
#
#        @player_contact.activity_logs.delete_all
#
#        expect {
#          attr = {master_id: @player_contact.master_id, item_controller: 'player_contacts', item_id: @player_contact.id, activity_log: {activity_log_name_id: [@activity_log_name.id]} }
#          post :create, attr
#        }.to change(object_class, :count).by(1), "Didn't create a new item."
#      end
#
#      it "assigns a newly created item as @var" do
#        create_master
#        va = valid_attributes
#        attr = {master_id: @player_contact.master_id, item_controller: 'player_contacts', item_id: @player_contact.id, activity_log: {activity_log_name_id: [@activity_log_name.id]} }
#        post :create, attr
#
#        expect(assigns(objects_symbol)).to be_a(@player_contact.activity_logs.class), "Item was not persisted with atts #{va.inspect}"
#
#      end
#
#      it "return success" do
#
#        va = valid_attributes
#        attr = {master_id: @player_contact.master_id, item_controller: 'player_contacts', item_id: @player_contact.id, activity_log: {activity_log_name_id: [@activity_log_name.id]} }
#        post :create,  attr
#        expect(response).to have_http_status(200), "Didn't get a 200 response with atts #{va.inspect}"
#      end
#    end
#
#    context "with invalid params" do
#      it "checks the item is valid" do
#        create_item
#        attr = {master_id: @player_contact.master_id, item_controller: 'player_contacts', item_id: nil, activity_log: {activity_log_name_id: [@activity_log_name.id]} }
#        expect { post :create, attr}.to raise_error ActionController::UrlGenerationError
#
#        attr = {
#          master_id: @player_contact.master_id,
#          item_controller: 'masters',
#          item_id: @player_contact.id,
#          activity_log: {
#            activity_log_name_id: [@activity_log_name]
#          }
#        }
#        #expect { post :create, attr}.to raise_error ActionController::RoutingError
#        post :create, attr
#        expect(response).to have_http_status(404), "Didn't get a 404 response with attr #{attr.inspect}"
#      end
#
#
#      it "assigns a newly created but unsaved item as @var" do
#
#        #ia = invalid_attributes
#
#        expect(assigns(:activity_logs)).to be_nil, "Create should not return a value: #{item}"
#      end
#
#      it "re-renders the 'new' template" do
#        list_invalid_attributes.each do |inv|
#
#          post :create, inv
#          expect(response).to have_http_status(422), "expected #{response.status} to be 422 with data #{inv}"
#          expect(response.body).to eq "The request failed to validate"
#        end
#      end
#    end
#  end
#
#  describe "PUT #update" do
#    before_each_login_user
#    before_each_login_admin
#    context "with valid params" do
#      let(:new_attributes) {
#        new_attribs
#      }
#
#      it "updates the requested item" do
#        create_item
#
#        attr = {master_id: @player_contact.master_id, item_controller: 'player_contacts', item_id: @player_contact.id,  id: item_id}
#        u = "/masters/#{attr[:master_id]}/#{attr[:item_controller]}/#{attr[:item_id]}/activity_logs/#{attr[:id]}"
#        expect(patch: u).not_to be_routable
#
#      end
#
#
#    end
#
#  end

  describe "DELETE #destroy" do
    before_each_login_user
    before_each_login_admin
    it "never destroys the requested item" do
      create_item
      expect(:delete => "activity_logs/#{item_id}").not_to be_routable
      expect(:delete => "masters/1/player_contacts/2/activity_logs/#{item_id}").not_to be_routable
      #delete :destroy, {:id => item_id, master_id: @master_id}
      #expect(response).to have_http_status(401)
    end


  end


end
