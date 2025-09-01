class Category < ApplicationRecord
  belongs_to :company

  has_many :product_categories, dependent: :destroy
  has_many :products, through: :product_categories

  validates :name, presence: true, uniqueness: { scope: :company_id }
end
