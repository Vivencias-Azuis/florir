class GoalProgress < ApplicationRecord
  belongs_to :goal, class_name: "TherapeuticGoal"
  belongs_to :session, class_name: "TherapySession"
  belongs_to :therapist, class_name: "User", foreign_key: :therapist_id

  validates :score, numericality: { in: 0..100 }
  validates :recorded_at, presence: true
end
