require "test_helper"

class TherapySessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-sess", email: "sess@tea.com")
    Current.clinic_id = @clinic.id
    @therapist = User.create!(clinic: @clinic, name: "Dra. Ana", email: "ana@tea.com",
                               password: "senha123", role: "therapist")
    @patient = Patient.create!(name: "Pedro", birth_date: 8.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
    @token = TokenService.encode(user_id: @therapist.id, clinic_id: @clinic.id, role: "therapist")
    Current.reset
  end

  test "create schedules session" do
    post "/therapy_sessions", headers: { "Authorization" => "Bearer #{@token}" },
         params: { patient_id: @patient.id, therapist_id: @therapist.id,
                   scheduled_at: 1.day.from_now.iso8601,
                   duration_minutes: 60, status: "scheduled", modality: "aba" }, as: :json
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "scheduled", json["status"]
  end

  test "index returns sessions for patient" do
    Current.clinic_id = @clinic.id
    TherapySession.create!(patient: @patient, therapist_id: @therapist.id,
                            scheduled_at: 1.day.from_now, duration_minutes: 60,
                            status: "scheduled", modality: "aba")
    Current.reset

    get "/patients/#{@patient.id}/sessions", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    assert_equal 1, JSON.parse(response.body).length
  end
end
