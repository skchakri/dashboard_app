class ProductImportService
  def initialize(company, product_data)
    @company = company
    @product_data = product_data
  end

  def call
    ActiveRecord::Base.transaction do
      upsert_product
      { success: true, product: @product, action: @action }
    end
  rescue StandardError => e
    { success: false, errors: [ e.message ] }
  end

  private

  def upsert_product
    @product = @company.products.find_by(sku: @product_data["sku"])
    @action = @product ? "updated" : "created"

    if @product
      update_existing_product
    else
      create_new_product
    end

    sync_categories if @product_data["categories"]
    sync_keywords if @product_data["keywords"]
    sync_images if @product_data["images"]
    sync_market_data if @product_data["markets"]
  end

  def create_new_product
    @product = @company.products.create!(
      sku: @product_data["sku"],
      status: @product_data["status"] || "active",
      stock_quantity: @product_data["stock_quantity"] || 0,
      track_inventory: @product_data["track_inventory"] || true,
      featured: @product_data["featured"] || false,
      base_name: @product_data["base_name"],
      base_description: @product_data["base_description"],
      base_price: @product_data["base_price"]
    )
  end

  def update_existing_product
    @product.update!(
      status: @product_data["status"] || @product.status,
      stock_quantity: @product_data["stock_quantity"] || @product.stock_quantity,
      track_inventory: @product_data.key?("track_inventory") ? @product_data["track_inventory"] : @product.track_inventory,
      featured: @product_data.key?("featured") ? @product_data["featured"] : @product.featured,
      base_name: @product_data["base_name"] || @product.base_name,
      base_description: @product_data["base_description"] || @product.base_description,
      base_price: @product_data["base_price"] || @product.base_price
    )
  end

  def sync_categories
    return unless @product_data["categories"]

    new_category_names = @product_data["categories"].map(&:strip).uniq
    new_categories = new_category_names.map do |category_name|
      @company.categories.find_or_create_by(name: category_name)
    end

    @product.categories = new_categories
  end

  def sync_keywords
    return unless @product_data["keywords"]

    @product.product_keywords.destroy_all
    @product_data["keywords"].each do |keyword|
      @product.product_keywords.create!(keyword: keyword.strip) if keyword.strip.present?
    end
  end

  def sync_images
    return unless @product_data["images"]

    @product.product_images.destroy_all
    @product_data["images"].each_with_index do |image_data, index|
      next unless image_data["url"].present?

      @product.product_images.create!(
        alt_text: image_data["alt_text"] || @product.base_name,
        sort_order: image_data["sort_order"] || (index + 1),
        image_url: image_data["url"]
      )
    end
  end

  def sync_market_data
    return unless @product_data["markets"]

    @product_data["markets"].each do |market_code, market_data|
      market = @company.markets.find_or_create_by(
        code: market_code.strip.downcase
      ) do |m|
        m.name = market_data["market_name"] || market_code.upcase
        m.currency = market_data["currency"] || "USD"
        m.active = true
      end

      product_market = @product.product_markets.find_or_initialize_by(market: market)
      product_market.assign_attributes(
        name: market_data["name"] || @product.base_name,
        description: market_data["description"] || @product.base_description,
        price: market_data["price"] || @product.base_price,
        available: market_data["available"] != false,
        special_price: market_data["special_price"],
        special_price_start: parse_date(market_data["special_price_start"]),
        special_price_end: parse_date(market_data["special_price_end"])
      )
      product_market.save!
    end
  end

  def parse_date(date_string)
    return nil unless date_string.present?
    Date.parse(date_string.to_s)
  rescue ArgumentError
    nil
  end
end
