require 'test_helper'

class MsControllerTest < ActionController::TestCase
  setup do
    @m = ms(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create m" do
    assert_difference('M.count') do
      post :create, m: {  }
    end

    assert_redirected_to m_path(assigns(:m))
  end

  test "should show m" do
    get :show, id: @m
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @m
    assert_response :success
  end

  test "should update m" do
    patch :update, id: @m, m: {  }
    assert_redirected_to m_path(assigns(:m))
  end

  test "should destroy m" do
    assert_difference('M.count', -1) do
      delete :destroy, id: @m
    end

    assert_redirected_to ms_path
  end
end
