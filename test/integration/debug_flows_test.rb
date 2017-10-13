require 'test_helper'

class DebugFlowsTest < ActionDispatch::IntegrationTest
  test "Echo Message" do
    get "/echo/message?message=Hello%20World"
    assert_response :success, "Could not GET echo message endpoint"
    assert_equal "Hello World", response.body

    post "/echo/message", params: { message: "Hello World" }
    assert_response :success, "Could not POST echo message endpoint"
    assert_equal "Hello World", response.body
  end

  test "Echo Auth" do
    post "/echo/auth", params: { message: "Hello World" }
    assert_response 401, "Echo auth should fail with Unauthorized"
  end
end
