require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  def create_columns
    ColumnTitle.create(column: 1, title: "Timestamp")
    ColumnTitle.create(column: 2, title: "Name")
    ColumnTitle.create(column: 3, title: "Email")
    ColumnTitle.create(column: 4, title: "SecureUDID")
    ColumnTitle.create(column: 5, title: "Problem Description")
  end

  def login_user
    testemail = 'camviewer@mckerrell.net'
    testpassword = 'V8WBQAiEhi30'
    u = User.create(:email => testemail, :password => testpassword)

    post_via_redirect "/users/sign_in", 'user[email]' => testemail, 'user[password]' => testpassword
    assert_response :success, "Did not log in ok"
  end

  def post_feedback
    #Make sure we've got a feedback to play with
    post "/feedback",
      { "entry.17.single"=>"1.0.0", "entry.3.single"=>"I have a major problem", "entry.6.single"=>"cameraUsername", "entry.11.single"=>"2017-06-20 03:32:17  0000", "entry.22.single"=>"9", "entry.18.single"=>"No", "entry.15.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.12.single"=>"Cell", "entry.19.single"=>"BADDECAF-0000-BADD-ECAF-00BADDECAF00", "entry.20.single"=>"7", "entry.16.single"=>"iRails1,3", "entry.9.single"=>"Advanced Direct Image (No Audio)", "entry.1.single"=>"noone@example.com", "entry.4.single"=>"cameraName HOME", "entry.7.single"=>"cameraPassword", "entry.2.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.8.single"=>"2017-06-20 03:32:17  0000", "entry.5.single"=>"http://camera.example.com/address", "entry.0.single"=>"Mr Example Name", "entry.21.single"=>"5", "entry.10.single"=>"10.10.10-10" }
    assert_response :success, "Basic creation wasn't successful"
    f = Feedback.first
    assert_not_nil f, "Basic creation did not result in feedback being created"
    assert_equal "", f.status, "First feedback creation should give empty status"
  end

  setup do
    create_columns
    login_user
    post_feedback
  end

  test "User login and flow" do
    get "/feedback/list"
    assert_response :success, "Could not access list page"
  end

  test "Searching" do
    get "/feedback/search"
    assert_response :success, "Could not access search page"
    assert_select "input", { attributes: { value: "noone@example.com" }}, false
    post "/feedback/search", email_address: "noone@example.com"
    assert_response :success, "Could not search for an email"
    assert_select "input", { attributes: { value: "noone@example.com" }}, "Could not find test email address in response"
    post "/feedback/search", failure_status: "null"
    assert_response :success, "Could not search for failure status"
    assert_select "h3", "0 results found", "Got too many search results"
  end

  test "analyse endpoint" do
    get "/feedback/analyse.txt"
    assert_response :success, "Could not access analyse page"
  end

  test "Submitting Handled status" do
    f = Feedback.first

    post_via_redirect "/feedback/#{f.id}/status?status=H"
    assert_response :success, "Could not set status as handled"
    assert_select "h3", "All feedback dealt with (of 1 entries)!"

    f.reload
    assert_equal "H", f.status, "Didn't set status to H"
  end

  test "Submitting General status" do
    f = Feedback.first

    post_via_redirect "/feedback/#{f.id}/status?status=General"
    assert_response :success, "Could not set status as general"
    assert_select "h3", "All feedback dealt with (of 1 entries)!"

    f.reload
    assert_equal "General", f.status, "Didn't set status to General"
  end

  test "Submitting General status, editing email" do
    f = Feedback.first

    post "/feedback/#{f.id}/status?status=General&email=Edit"
    assert_response :success, "Could not set status as general"
    assert_select "h3", {count: 0, text:"All feedback dealt with (of 1 entries)!" }

    f.reload
    assert_equal "", f.status, "Set status to General without filling in form"
  end

  test "Submitting Special status" do
    f = Feedback.first

    post "/feedback/#{f.id}/status?status=Special"
    assert_response :success, "Could not set status as special"
    assert_select "h3", {count: 0, text:"All feedback dealt with (of 1 entries)!" }

    f.reload
    assert_equal "", f.status, "Set status to Special without filling in form"
  end
end
