require "test_helper"

class TherapySessionTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-session", email: "s@s.com")
    Current.clinic_id = @clinic.id
    @therapist = User.create!(clinic: @clinic, name: "Dra. Camila", email: "camila@tea.com",
                               password: "secret123", role: "therapist")
    @patient = Patient.create!(name: "Ana", birth_date: 7.years.ago,
                                diagnosis_level: 2, communication_method: "aac")
  end

  teardown { Current.reset }

  test "valid session" do
    s = TherapySession.new(patient: @patient, therapist: @therapist,
                            scheduled_at: 1.day.from_now, status: "scheduled",
                            modality: "aba")
    assert s.valid?
  end

  test "invalid without scheduled_at" do
    s = TherapySession.new(patient: @patient, therapist: @therapist,
                            status: "scheduled", modality: "aba")
    assert_not s.valid?
    assert_includes s.errors[:scheduled_at], "can't be blank"
  end

  test "invalid status" do
    s = TherapySession.new(patient: @patient, therapist: @therapist,
                            scheduled_at: 1.day.from_now, status: "unknown")
    assert_not s.valid?
  end
end
