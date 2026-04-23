require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-auth", email: "auth@tea.com")
    Current.clinic_id = @clinic.id
    @user = User.create!(clinic: @clinic, name: "Dra. Camila", email: "camila@tea.com",
                         password: "senha123", role: "admin")
    Current.reset
  end

  test "register creates clinic and admin user" do
    post "/auth/register", params: {
      clinic: { name: "Nova Clínica", slug: "nova-clinica", email: "nova@tea.com" },
      user: { name: "Admin", email: "admin@nova.com", password: "senha456" }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert_equal "admin", json["user"]["role"]
  end

  test "login returns token on valid credentials" do
    post "/auth/login", params: { email: "camila@tea.com", password: "senha123",
                                   clinic_slug: "tea-auth" }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["token"].present?
  end

  test "login returns 401 on wrong password" do
    post "/auth/login", params: { email: "camila@tea.com", password: "errada",
                                   clinic_slug: "tea-auth" }, as: :json
    assert_response :unauthorized
  end
end
