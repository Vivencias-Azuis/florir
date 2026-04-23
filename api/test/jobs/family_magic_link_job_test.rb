require "test_helper"

class FamilyMagicLinkJobTest < ActiveJob::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea-job", email: "job@tea.com")
    Current.clinic_id = @clinic.id
    @user = User.create!(clinic: @clinic, name: "Mãe", email: "mae@job.com",
                         password: "senha123", role: "family")
    @patient = Patient.create!(name: "Filho", birth_date: 5.years.ago,
                                diagnosis_level: 1, communication_method: "verbal")
    @access = FamilyAccess.create!(patient: @patient, user: @user,
                                    relation: "mother", active: true)
    Current.reset
  end

  test "enqueues magic link email" do
    assert_enqueued_with(job: FamilyMagicLinkJob) do
      FamilyMagicLinkJob.perform_later(@access.id)
    end
  end

  test "performs without error" do
    assert_nothing_raised { FamilyMagicLinkJob.perform_now(@access.id) }
  end
end
