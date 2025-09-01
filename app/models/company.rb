class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :markets, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_one_attached :icon

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" }

  def self.find_by_subdomain(subdomain)
    find_by(subdomain: subdomain)
  end
end
