class Product < ApplicationRecord
  belongs_to :company

  has_many :product_markets, dependent: :destroy
  has_many :markets, through: :product_markets
  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories
  has_many :product_images, -> { order(:sort_order) }, dependent: :destroy
  has_many :product_keywords, dependent: :destroy

  accepts_nested_attributes_for :product_markets, allow_destroy: true
  accepts_nested_attributes_for :product_keywords, allow_destroy: true
  accepts_nested_attributes_for :product_images, allow_destroy: true

  enum status: { active: 0, inactive: 1, discontinued: 2 }

  validates :sku, presence: true, uniqueness: { scope: :company_id }
  validates :base_name, presence: true
  validates :base_price, presence: true, numericality: { greater_than: 0 }
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :featured, -> { where(featured: true) }
  scope :available, -> { where(status: :active) }

  def display_name(market = nil)
    return base_name unless market
    product_markets.find_by(market: market)&.name || base_name
  end

  def display_description(market = nil)
    return base_description unless market
    product_markets.find_by(market: market)&.description || base_description
  end

  def display_price(market = nil)
    return base_price unless market
    market_data = product_markets.find_by(market: market)
    return base_price unless market_data

    if market_data.special_price.present? &&
       market_data.special_price_start&.<=(Date.current) &&
       market_data.special_price_end&.>=(Date.current)
      market_data.special_price
    else
      market_data.price || base_price
    end
  end

  def available_in_market?(market)
    market_data = product_markets.find_by(market: market)
    market_data&.available || false
  end
end
