class ImageGenerationJob < ApplicationJob
  queue_as :default

  def perform(product_id, market_id, user_id)
    product = Product.find(product_id)
    market = Market.find(market_id)
    user = User.find(user_id)

    # Default platform config for image generation
    platform_config = {
      platform: "instagram",
      image_size: "1080x1080",
      image_ratio: "1:1"
    }

    # Use the ImageGenerationService for proper image generation
    image_service = ImageGenerationService.new(
      product: product,
      market: market,
      audience_type: "millennials",
      message_tone: "friendly",
      user: user
    )

    images = image_service.generate_images_for_platform(platform_config)

    # Save the first generated image
    if images.any? && images.first[:url]
      ProductImage.create!(
        product_id: product_id,
        image_url: images.first[:url],
        alt_text: "Generated image for #{product.display_name(market)}",
        sort_order: 1
      )
    end
  end
end
