class User < ApplicationRecord
  include TenantScoped

  has_secure_password

  ROLES = %w[admin therapist family].freeze

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :clinic_id }
  validates :role, inclusion: { in: ROLES }

  scope :therapists, -> { where(role: %w[admin therapist]) }
end
