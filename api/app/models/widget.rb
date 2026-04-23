class Widget < ApplicationRecord
  validates :name, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
