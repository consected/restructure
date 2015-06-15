require 'test_helper'

class ScantronsControllerTest < ActionController::TestCase
  setup do
    @scantron = scantrons(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:scantrons)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scantron" do
    assert_difference('Scantron.count') do
      post :create, scantron: { master_id: @scantron.master_id, rank: @scantron.rank, scantron_id: @scantron.scantron_id, source: @scantron.source, user_id: @scantron.user_id }
    end

    assert_redirected_to scantron_path(assigns(:scantron))
  end

  test "should show scantron" do
    get :show, id: @scantron
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @scantron
    assert_response :success
  end

  test "should update scantron" do
    patch :update, id: @scantron, scantron: { master_id: @scantron.master_id, rank: @scantron.rank, scantron_id: @scantron.scantron_id, source: @scantron.source, user_id: @scantron.user_id }
    assert_redirected_to scantron_path(assigns(:scantron))
  end

  test "should destroy scantron" do
    assert_difference('Scantron.count', -1) do
      delete :destroy, id: @scantron
    end

    assert_redirected_to scantrons_path
  end
end
