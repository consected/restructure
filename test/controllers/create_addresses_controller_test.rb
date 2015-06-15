require 'test_helper'

class CreateAddressesControllerTest < ActionController::TestCase
  setup do
    @create_address = create_addresses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:create_addresses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create create_address" do
    assert_difference('CreateAddress.count') do
      post :create, create_address: { city: @create_address.city, master_id: @create_address.master_id, rank: @create_address.rank, source: @create_address.source, state: @create_address.state, street2: @create_address.street2, street3: @create_address.street3, street: @create_address.street, type: @create_address.type, zip: @create_address.zip }
    end

    assert_redirected_to create_address_path(assigns(:create_address))
  end

  test "should show create_address" do
    get :show, id: @create_address
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @create_address
    assert_response :success
  end

  test "should update create_address" do
    patch :update, id: @create_address, create_address: { city: @create_address.city, master_id: @create_address.master_id, rank: @create_address.rank, source: @create_address.source, state: @create_address.state, street2: @create_address.street2, street3: @create_address.street3, street: @create_address.street, type: @create_address.type, zip: @create_address.zip }
    assert_redirected_to create_address_path(assigns(:create_address))
  end

  test "should destroy create_address" do
    assert_difference('CreateAddress.count', -1) do
      delete :destroy, id: @create_address
    end

    assert_redirected_to create_addresses_path
  end
end
