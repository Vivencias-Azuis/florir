class Patient < ApplicationRecord
  include TenantScoped

  COMMUNICATION_METHODS = %w[verbal non_verbal aac].freeze
  DIAGNOSIS_LEVELS = [1, 2, 3].freeze

  has_many :therapy_sessions, dependent: :destroy
  has_many :therapeutic_goals, dependent: :destroy
  has_many :family_accesses, dependent: :destroy

  validates :name, presence: true
  validates :diagnosis_level, inclusion: { in: DIAGNOSIS_LEVELS }, allow_nil: true
  validates :communication_method, inclusion: { in: COMMUNICATION_METHODS }, allow_nil: true
end
