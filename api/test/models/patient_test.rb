require "test_helper"

class PatientTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-test", email: "c@c.com")
    Current.clinic_id = @clinic.id
  end

  teardown { Current.reset }

  test "valid patient" do
    p = Patient.new(name: "Ana Luiza", birth_date: 10.years.ago,
                    diagnosis_level: 2, communication_method: "aac")
    assert p.valid?
  end

  test "invalid without name" do
    p = Patient.new(birth_date: 5.years.ago)
    assert_not p.valid?
    assert_includes p.errors[:name], "can't be blank"
  end

  test "invalid diagnosis_level outside 1-3" do
    p = Patient.new(name: "X", birth_date: 5.years.ago, diagnosis_level: 5)
    assert_not p.valid?
  end

  test "clinic_id set from Current" do
    p = Patient.create!(name: "Lucas", birth_date: 6.years.ago,
                        diagnosis_level: 1, communication_method: "verbal")
    assert_equal @clinic.id, p.clinic_id
  end
end
