require 'test_helper'

class PlayerContactsControllerTest < ActionController::TestCase
  setup do
    @player_contact = player_contacts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:player_contacts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create player_contact" do
    assert_difference('PlayerContact.count') do
      post :create, player_contact: { active: @player_contact.active, master_id: @player_contact.master_id, pcdata: @player_contact.pcdata, pcdate: @player_contact.pcdate, pctype: @player_contact.pctype, rank: @player_contact.rank, source: @player_contact.source }
    end

    assert_redirected_to player_contact_path(assigns(:player_contact))
  end

  test "should show player_contact" do
    get :show, id: @player_contact
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @player_contact
    assert_response :success
  end

  test "should update player_contact" do
    patch :update, id: @player_contact, player_contact: { active: @player_contact.active, master_id: @player_contact.master_id, pcdata: @player_contact.pcdata, pcdate: @player_contact.pcdate, pctype: @player_contact.pctype, rank: @player_contact.rank, source: @player_contact.source }
    assert_redirected_to player_contact_path(assigns(:player_contact))
  end

  test "should destroy player_contact" do
    assert_difference('PlayerContact.count', -1) do
      delete :destroy, id: @player_contact
    end

    assert_redirected_to player_contacts_path
  end
end
