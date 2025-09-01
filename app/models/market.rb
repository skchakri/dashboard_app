class Market < ApplicationRecord
  belongs_to :company

  has_many :product_markets, dependent: :destroy
  has_many :products, through: :product_markets

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :currency, presence: true

  scope :active, -> { where(active: true) }
end
