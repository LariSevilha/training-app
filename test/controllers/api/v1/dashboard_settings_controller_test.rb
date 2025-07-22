require "test_helper"

class Api::V1::DashboardSettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_dashboard_settings_index_url
    assert_response :success
  end

  test "should get show" do
    get api_v1_dashboard_settings_show_url
    assert_response :success
  end

  test "should get create" do
    get api_v1_dashboard_settings_create_url
    assert_response :success
  end

  test "should get update" do
    get api_v1_dashboard_settings_update_url
    assert_response :success
  end
end
