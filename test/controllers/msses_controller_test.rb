require 'test_helper'

class MssesControllerTest < ActionController::TestCase
  setup do
    @mss = msses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:msses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create mss" do
    assert_difference('Mss.count') do
      post :create, mss: {  }
    end

    assert_redirected_to mss_path(assigns(:mss))
  end

  test "should show mss" do
    get :show, id: @mss
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @mss
    assert_response :success
  end

  test "should update mss" do
    patch :update, id: @mss, mss: {  }
    assert_redirected_to mss_path(assigns(:mss))
  end

  test "should destroy mss" do
    assert_difference('Mss.count', -1) do
      delete :destroy, id: @mss
    end

    assert_redirected_to msses_path
  end
end
