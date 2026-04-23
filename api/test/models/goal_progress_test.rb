require "test_helper"

class GoalProgressTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-progress", email: "p@p.com")
    Current.clinic_id = @clinic.id
    @therapist = User.create!(clinic: @clinic, name: "Dra. Camila", email: "cam@tea.com",
                               password: "secret123", role: "therapist")
    @patient = Patient.create!(name: "Pedro", birth_date: 8.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
    @goal = TherapeuticGoal.create!(patient: @patient, domain: "communication",
                                     title: "Usar PECS", status: "active")
    @session = TherapySession.create!(patient: @patient, therapist: @therapist,
                                       scheduled_at: Time.current, status: "completed",
                                       modality: "pecs")
  end

  teardown { Current.reset }

  test "valid progress" do
    gp = GoalProgress.new(goal: @goal, session: @session, therapist: @therapist,
                           score: 75, recorded_at: Time.current)
    assert gp.valid?
  end

  test "invalid score above 100" do
    gp = GoalProgress.new(goal: @goal, session: @session, therapist: @therapist,
                           score: 101, recorded_at: Time.current)
    assert_not gp.valid?
  end

  test "invalid score below 0" do
    gp = GoalProgress.new(goal: @goal, session: @session, therapist: @therapist,
                           score: -1, recorded_at: Time.current)
    assert_not gp.valid?
  end
end
