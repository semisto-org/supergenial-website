require "test_helper"

class TwoFactorTest < ActionDispatch::IntegrationTest
  def code_for(user, at: Time.current) = ROTP::TOTP.new(user.otp_secret).at(at)

  test "a user with two-factor enters the code after the password" do
    user = users(:one)
    post session_path, params: { email_address: user.email_address, password: "password" }
    assert_redirected_to new_two_factor_path
    assert_nil cookies[:session_id].presence

    post two_factor_path, params: { code: "000000" }
    assert_redirected_to new_two_factor_path

    post two_factor_path, params: { code: code_for(user) }
    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "a code cannot be replayed" do
    user = users(:one)
    code = code_for(user)
    assert user.verify_otp(code)
    assert_not user.reload.verify_otp(code)
  end

  test "the code step expires" do
    user = users(:one)
    post session_path, params: { email_address: user.email_address, password: "password" }
    travel 6.minutes do
      post two_factor_path, params: { code: code_for(user) }
      assert_redirected_to new_session_path
    end
  end

  test "a user without two-factor must set it up before anything else" do
    user = users(:two)
    post session_path, params: { email_address: user.email_address, password: "password" }
    assert_redirected_to two_factor_setup_path

    get root_path
    assert_redirected_to two_factor_setup_path

    get two_factor_setup_path
    assert_response :success
    secret = session[:otp_setup_secret]

    post two_factor_setup_path, params: { code: "123456" }
    assert_redirected_to two_factor_setup_path
    assert_not user.reload.two_factor_enabled?

    post two_factor_setup_path, params: { code: ROTP::TOTP.new(secret).now }
    assert user.reload.two_factor_enabled?
    get root_path
    assert_response :success
  end

  test "sessions expire after 30 days" do
    sign_in_as users(:one)
    travel 31.days do
      get root_path
      assert_redirected_to new_session_path
    end
  end
end
