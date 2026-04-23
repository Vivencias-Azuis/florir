class Clinic < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :patients, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, hyphens" }
  validates :email, presence: true
end
