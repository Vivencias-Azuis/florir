require "test_helper"

class ClinicTest < ActiveSupport::TestCase
  test "valid with required fields" do
    clinic = Clinic.new(name: "Clínica TEA", slug: "clinica-tea", email: "admin@tea.com")
    assert clinic.valid?
  end

  test "invalid without name" do
    clinic = Clinic.new(slug: "tea", email: "x@x.com")
    assert_not clinic.valid?
    assert_includes clinic.errors[:name], "can't be blank"
  end

  test "invalid with duplicate slug" do
    Clinic.create!(name: "A", slug: "slug-a", email: "a@a.com")
    clinic = Clinic.new(name: "B", slug: "slug-a", email: "b@b.com")
    assert_not clinic.valid?
  end
end
