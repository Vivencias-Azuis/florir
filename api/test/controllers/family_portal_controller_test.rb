require "test_helper"

class FamilyPortalControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-portal", email: "portal@tea.com")
    Current.clinic_id = @clinic.id
    @family_user = User.create!(clinic: @clinic, name: "Mãe", email: "mae@email.com",
                                 password: "senha123", role: "family")
    @patient = Patient.create!(name: "Ana", birth_date: 7.years.ago,
                                diagnosis_level: 2, communication_method: "aac")
    @access = FamilyAccess.create!(patient: @patient, user: @family_user,
                                    relation: "mother", active: true)
    Current.reset
  end

  test "dashboard returns patient info and goals" do
    get "/family/#{@access.access_token}/dashboard"
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Ana", json["patient"]["name"]
    assert json.key?("goals")
  end

  test "invalid token returns 404" do
    get "/family/invalid-token/dashboard"
    assert_response :not_found
  end
end
