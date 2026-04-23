require "test_helper"

class TherapeuticGoalTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-goal", email: "g@g.com")
    Current.clinic_id = @clinic.id
    @patient = Patient.create!(name: "Pedro", birth_date: 8.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
  end

  teardown { Current.reset }

  test "valid goal" do
    g = TherapeuticGoal.new(patient: @patient, domain: "communication",
                             method: "pecs", title: "Usar PECS espontaneamente",
                             status: "active")
    assert g.valid?
  end

  test "invalid domain" do
    g = TherapeuticGoal.new(patient: @patient, domain: "invalid",
                             method: "aba", title: "X", status: "active")
    assert_not g.valid?
  end

  test "invalid status" do
    g = TherapeuticGoal.new(patient: @patient, domain: "communication",
                             method: "aba", title: "X", status: "unknown")
    assert_not g.valid?
  end
end
