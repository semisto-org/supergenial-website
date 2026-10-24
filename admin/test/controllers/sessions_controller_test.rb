require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials asks for the second factor" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to new_two_factor_path
    assert_nil cookies[:session_id]
  end

  test "create without two-factor yet opens a session limited to its setup" do
    post session_path, params: { email_address: users(:two).email_address, password: "password" }

    assert_redirected_to two_factor_setup_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
