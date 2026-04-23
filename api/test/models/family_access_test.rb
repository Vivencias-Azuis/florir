require "test_helper"

class FamilyAccessTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-fam", email: "f@f.com")
    Current.clinic_id = @clinic.id
    @patient = Patient.create!(name: "Ana", birth_date: 7.years.ago,
                                diagnosis_level: 2, communication_method: "aac")
    @user = User.create!(clinic: @clinic, name: "Mãe Ana", email: "mae@email.com",
                         password: "senha123", role: "family")
  end

  teardown { Current.reset }

  test "generates access_token on create" do
    fa = FamilyAccess.create!(patient: @patient, user: @user,
                               relation: "mother", active: true)
    assert_not_nil fa.access_token
    assert fa.access_token.length >= 32
  end

  test "invalid relation" do
    fa = FamilyAccess.new(patient: @patient, user: @user,
                          relation: "alien", active: true)
    assert_not fa.valid?
  end

  test "token is unique per record" do
    fa1 = FamilyAccess.create!(patient: @patient, user: @user, relation: "mother", active: true)
    # A second access can be created with a different user or same user — token must differ
    user2 = User.create!(clinic: @clinic, name: "Pai João", email: "pai@email.com",
                         password: "senha123", role: "family")
    fa2 = FamilyAccess.create!(patient: @patient, user: user2, relation: "father", active: true)
    assert_not_equal fa1.access_token, fa2.access_token
  end
end
