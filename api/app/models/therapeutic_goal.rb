class TherapeuticGoal < ApplicationRecord
  include TenantScoped

  DOMAINS = %w[communication social_skills behavior motor daily_living cognitive].freeze
  METHODS = %w[aba pecs dir_floortime vb_mapp other].freeze
  STATUSES = %w[active achieved paused discontinued].freeze

  belongs_to :patient
  has_many :goal_progresses, foreign_key: :goal_id, dependent: :destroy

  validates :title, presence: true
  validates :domain, inclusion: { in: DOMAINS }
  validates :method, inclusion: { in: METHODS }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }
end
