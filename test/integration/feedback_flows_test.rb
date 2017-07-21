require 'test_helper'

class FeedbackFlowsTest < ActionDispatch::IntegrationTest
  test "Feedback creation" do
    assert_nil Feedback.first

    #Basic creation
    post "/feedback",
      params: { "entry.17.single"=>"1.0.0", "entry.3.single"=>"I have a major problem", "entry.6.single"=>"cameraUsername", "entry.11.single"=>"2017-06-20 03:32:17  0000", "entry.22.single"=>"9", "entry.18.single"=>"No", "entry.15.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.12.single"=>"Cell", "entry.19.single"=>"BADDECAF-0000-BADD-ECAF-00BADDECAF00", "entry.20.single"=>"7", "entry.16.single"=>"iRails1,3", "entry.9.single"=>"Advanced Direct Image (No Audio)", "entry.1.single"=>"noone@example.com", "entry.4.single"=>"cameraName HOME", "entry.7.single"=>"cameraPassword", "entry.2.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.8.single"=>"2017-06-20 03:32:17  0000", "entry.5.single"=>"http://camera.example.com/address", "entry.0.single"=>"Mr Example Name", "entry.21.single"=>"5", "entry.10.single"=>"10.10.10-10" }
    assert_response :success, "Basic creation wasn't successful"
    f = Feedback.first
    assert_not_nil f, "Basic creation did not result in feedback being created"
    assert_equal "", f.status, "First feedback creation should give empty status"

    # Exact Duplicate
    post "/feedback",
      params: { "entry.17.single"=>"1.0.0", "entry.3.single"=>"I have a major problem", "entry.6.single"=>"cameraUsername", "entry.11.single"=>"2017-06-20 03:32:17  0000", "entry.22.single"=>"9", "entry.18.single"=>"No", "entry.15.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.12.single"=>"Cell", "entry.19.single"=>"BADDECAF-0000-BADD-ECAF-00BADDECAF00", "entry.20.single"=>"7", "entry.16.single"=>"iRails1,3", "entry.9.single"=>"Advanced Direct Image (No Audio)", "entry.1.single"=>"noone@example.com", "entry.4.single"=>"cameraName HOME", "entry.7.single"=>"cameraPassword", "entry.2.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.8.single"=>"2017-06-20 03:32:17  0000", "entry.5.single"=>"http://camera.example.com/address", "entry.0.single"=>"Mr Example Name", "entry.21.single"=>"5", "entry.10.single"=>"10.10.10-10" }

    assert_equal 1, Feedback.count, "Posting exact duplicate feedback should not have added another feedback"

    sleep 1
    post "/feedback",
      params: { "entry.17.single"=>"1.0.0", "entry.3.single"=>"I have a major problem", "entry.6.single"=>"cameraUsername", "entry.11.single"=>"2017-06-20 03:32:17  0000", "entry.22.single"=>"9", "entry.18.single"=>"No", "entry.15.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.12.single"=>"Cell", "entry.19.single"=>"BADDECAF-0000-BADD-ECAF-00BADDECAF00", "entry.20.single"=>"7", "entry.16.single"=>"iRails1,3", "entry.9.single"=>"Advanced Direct Image (No Audio)", "entry.1.single"=>"noone@example.com", "entry.4.single"=>"cameraName HOME", "entry.7.single"=>"cameraPassword", "entry.2.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.8.single"=>"2017-06-20 03:32:17  0000", "entry.5.single"=>"http://camera.example.com/address", "entry.0.single"=>"Mr Example Name", "entry.21.single"=>"5", "entry.10.single"=>"10.10.10-10" }
    assert_response :success, "Posting duplicate feedback wasn't successful"
    assert_equal 2, Feedback.count, "Posting duplicate feedback should have added another feedback"
    f = Feedback.last
    assert_equal "Duplicate", f.status, "Second feedback creation should give Duplicate status"


    sleep 2
    # Duplicate but problem description is slightly changed
    post "/feedback",
      params: { "entry.17.single"=>"1.0.0", "entry.3.single"=>"I have a huge major problem", "entry.6.single"=>"cameraUsername", "entry.11.single"=>"2017-06-20 03:32:17  0000", "entry.22.single"=>"9", "entry.18.single"=>"No", "entry.15.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.12.single"=>"Cell", "entry.19.single"=>"BADDECAF-0000-BADD-ECAF-00BADDECAF00", "entry.20.single"=>"7", "entry.16.single"=>"iRails1,3", "entry.9.single"=>"Advanced Direct Image (No Audio)", "entry.1.single"=>"noone@example.com", "entry.4.single"=>"cameraName HOME", "entry.7.single"=>"cameraPassword", "entry.2.single"=>"DECAFBAD-0000-DECA-FBAD-00DECAFBAD00", "entry.8.single"=>"2017-06-20 03:32:17  0000", "entry.5.single"=>"http://camera.example.com/address", "entry.0.single"=>"Mr Example Name", "entry.21.single"=>"5", "entry.10.single"=>"10.10.10-10" }
    assert_response :success, "Posting duplicate with different description wasn't successful"
    assert_equal Feedback.count, 3, "Posting duplicate with different description should have added another feedback"
    f = Feedback.last
    assert_equal "", f.status, "Third feedback creation should give empty status"


    f = Feedback.first
    f.status = 'General'
    f.save!
  end
  # test "the truth" do
  #   assert true
  # end
end
