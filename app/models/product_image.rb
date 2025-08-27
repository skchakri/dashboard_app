class ProductImage < ApplicationRecord
  belongs_to :product
  
  has_one_attached :image
  
  validates :sort_order, presence: true, numericality: { greater_than: 0 }
  # Image validation is optional to allow URL-based imports
  # validates :image, presence: true
  
  scope :ordered, -> { order(:sort_order) }
end
