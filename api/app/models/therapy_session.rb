class TherapySession < ApplicationRecord
  include TenantScoped

  STATUSES = %w[scheduled confirmed completed cancelled no_show].freeze
  MODALITIES = %w[aba pecs dir_floortime speech occupational psycho other].freeze

  belongs_to :patient
  belongs_to :therapist, class_name: "User", foreign_key: :therapist_id

  validates :scheduled_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :modality, inclusion: { in: MODALITIES }, allow_nil: true
end
