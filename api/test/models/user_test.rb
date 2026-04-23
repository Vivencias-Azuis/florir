require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @clinic = Clinic.create!(name: "TEA", slug: "tea", email: "c@c.com")
    Current.clinic_id = @clinic.id
  end

  teardown do
    Current.reset
  end

  test "valid admin user" do
    user = User.new(clinic: @clinic, name: "Dra. Camila", email: "camila@tea.com",
                    password: "secret123", role: "admin")
    assert user.valid?
  end

  test "invalid with unknown role" do
    user = User.new(clinic: @clinic, name: "X", email: "x@x.com",
                    password: "secret123", role: "hacker")
    assert_not user.valid?
  end

  test "authenticate returns user on correct password" do
    User.create!(clinic: @clinic, name: "Dr. João", email: "joao@tea.com",
                 password: "senha123", role: "therapist")
    user = User.find_by(email: "joao@tea.com")
    assert user.authenticate("senha123")
    assert_not user.authenticate("errada")
  end
end
