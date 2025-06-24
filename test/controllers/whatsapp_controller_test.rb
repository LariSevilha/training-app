require "test_helper"

class WhatsappControllerTest < ActionDispatch::IntegrationTest
  test "should get send_message" do
    get whatsapp_send_message_url
    assert_response :success
  end
end
