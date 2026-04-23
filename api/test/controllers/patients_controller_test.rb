require "test_helper"

class PatientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-pat", email: "pat@tea.com")
    Current.clinic_id = @clinic.id
    @admin = User.create!(clinic: @clinic, name: "Admin", email: "admin@tea.com",
                          password: "senha123", role: "admin")
    @token = TokenService.encode(user_id: @admin.id, clinic_id: @clinic.id, role: "admin")
    @patient = Patient.create!(name: "Ana Luiza", birth_date: 7.years.ago,
                                diagnosis_level: 2, communication_method: "aac")
    Current.reset
  end

  test "index returns patients for clinic" do
    get "/patients", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal "Ana Luiza", json.first["name"]
  end

  test "show returns single patient" do
    get "/patients/#{@patient.id}", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    assert_equal "Ana Luiza", JSON.parse(response.body)["name"]
  end

  test "create adds patient" do
    post "/patients", headers: { "Authorization" => "Bearer #{@token}" },
         params: { name: "Pedro", birth_date: "2018-03-10",
                   diagnosis_level: 1, communication_method: "verbal" }, as: :json
    assert_response :created
  end

  test "cannot access patients from another clinic" do
    other_clinic = Clinic.create!(name: "Outra", slug: "outra", email: "o@o.com")
    Current.clinic_id = other_clinic.id
    other_patient = Patient.create!(name: "Intruso", birth_date: 5.years.ago, diagnosis_level: 1)
    Current.reset

    get "/patients/#{other_patient.id}", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :not_found
  end
end
