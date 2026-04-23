require "test_helper"

class TherapeuticGoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-goals", email: "goal@tea.com")
    Current.clinic_id = @clinic.id
    @therapist = User.create!(clinic: @clinic, name: "Dra. Julia", email: "julia@tea.com",
                               password: "senha123", role: "therapist")
    @patient = Patient.create!(name: "Bia", birth_date: 6.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
    @token = TokenService.encode(user_id: @therapist.id, clinic_id: @clinic.id, role: "therapist")
    Current.reset
  end

  test "create goal" do
    post "/therapeutic_goals", headers: { "Authorization" => "Bearer #{@token}" },
         params: { patient_id: @patient.id, domain: "communication",
                   method: "pecs", title: "Usar PECS espontaneamente",
                   status: "active" }, as: :json
    assert_response :created
    assert_equal "communication", JSON.parse(response.body)["domain"]
  end

  test "create progress for goal" do
    Current.clinic_id = @clinic.id
    session = TherapySession.create!(patient: @patient, therapist_id: @therapist.id,
                                      scheduled_at: 1.day.ago, duration_minutes: 60,
                                      status: "completed", modality: "pecs")
    goal = TherapeuticGoal.create!(patient: @patient, domain: "communication",
                                    method: "pecs", title: "PECS", status: "active")
    Current.reset

    post "/therapeutic_goals/#{goal.id}/progresses",
         headers: { "Authorization" => "Bearer #{@token}" },
         params: { session_id: session.id, therapist_id: @therapist.id,
                   score: 75, recorded_at: Time.current.iso8601 }, as: :json
    assert_response :created
    assert_equal 75, JSON.parse(response.body)["score"]
  end
end
