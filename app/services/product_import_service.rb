class ProductImportService
  def initialize(company, product_data)
    @company = company
    @product_data = product_data
  end

  def call
    ActiveRecord::Base.transaction do
      create_product
      { success: true, product: @product }
    end
  rescue StandardError => e
    { success: false, errors: [e.message] }
  end

  private

  def create_product
    @product = @company.products.build(
      sku: @product_data['sku'],
      status: @product_data['status'] || 'active',
      stock_quantity: @product_data['stock_quantity'] || 0,
      track_inventory: @product_data['track_inventory'] || true,
      featured: @product_data['featured'] || false,
      base_name: @product_data['base_name'],
      base_description: @product_data['base_description'],
      base_price: @product_data['base_price']
    )

    @product.save!

    create_categories if @product_data['categories']
    create_keywords if @product_data['keywords']
    create_images if @product_data['images']
    create_market_data if @product_data['markets']
  end

  def create_categories
    @product_data['categories'].each do |category_name|
      category = @company.categories.find_or_create_by(name: category_name)
      @product.categories << category unless @product.categories.include?(category)
    end
  end

  def create_keywords
    @product_data['keywords'].each do |keyword|
      @product.product_keywords.create!(keyword: keyword)
    end
  end

  def create_images
    @product_data['images'].each_with_index do |image_data, index|
      @product.product_images.create!(
        alt_text: image_data['alt_text'] || @product.base_name,
        sort_order: image_data['sort_order'] || (index + 1),
        image_url: image_data['url']
      )
    end
  end

  def create_market_data
    @product_data['markets'].each do |market_code, market_data|
      market = @company.markets.find_or_create_by(
        code: market_code,
        name: market_data['market_name'] || market_code.upcase,
        currency: market_data['currency'] || 'USD',
        active: true
      )

      @product.product_markets.create!(
        market: market,
        name: market_data['name'],
        description: market_data['description'],
        price: market_data['price'],
        available: market_data['available'] != false,
        special_price: market_data['special_price'],
        special_price_start: market_data['special_price_start']&.to_date,
        special_price_end: market_data['special_price_end']&.to_date
      )
    end
  end
end