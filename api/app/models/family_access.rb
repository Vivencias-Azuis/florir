class FamilyAccess < ApplicationRecord
  RELATIONS = %w[mother father guardian other].freeze

  belongs_to :patient
  belongs_to :user

  before_create :generate_token

  validates :relation, inclusion: { in: RELATIONS }
  validates :access_token, uniqueness: true, allow_nil: true

  private

  def generate_token
    self.access_token = SecureRandom.hex(24)
  end
end
