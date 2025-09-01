class SocialContentGenerationService
  def initialize(product:, market:, audience_type:, message_tone:, custom_message: nil, social_platform: "general", user: nil)
    @product = product
    @market = market
    @audience_type = audience_type
    @message_tone = message_tone
    @custom_message = custom_message
    @social_platform = social_platform
    @user = user

    # Initialize specialized services
    @content_service = ContentGenerationService.new(
      product: @product,
      market: @market,
      audience_type: @audience_type,
      message_tone: @message_tone,
      custom_message: @custom_message,
      user: @user
    )

    @image_service = ImageGenerationService.new(
      product: @product,
      market: @market,
      audience_type: @audience_type,
      message_tone: @message_tone,
      user: @user
    )
  end

  def generate_content
    platform_configs = get_platform_configs
    generated_contents = []

    platform_configs.each do |platform_config|
      # Generate content using ContentGenerationService
      content = @content_service.generate_content_for_platform(platform_config)

      # Generate images using ImageGenerationService
      content[:images] = @image_service.generate_images_for_platform(platform_config)

      generated_contents << content
    end

    generated_contents
  end

  private

  def get_platform_configs
    if @social_platform == "general"
      [
        { platform: "facebook", max_chars: 2200, style: "conversational", image_size: "1200x630", image_ratio: "16:9" },
        { platform: "instagram", max_chars: 2200, style: "visual", image_size: "1080x1080", image_ratio: "1:1" },
        { platform: "twitter", max_chars: 280, style: "concise", image_size: "1200x675", image_ratio: "16:9" },
        { platform: "linkedin", max_chars: 3000, style: "professional", image_size: "1200x627", image_ratio: "16:9" }
      ]
    else
      case @social_platform
      when "facebook"
        [ { platform: "facebook", max_chars: 2200, style: "conversational", image_size: "1200x630", image_ratio: "16:9" } ]
      when "instagram"
        [ { platform: "instagram", max_chars: 2200, style: "visual", image_size: "1080x1080", image_ratio: "1:1" } ]
      when "twitter"
        [ { platform: "twitter", max_chars: 280, style: "concise", image_size: "1200x675", image_ratio: "16:9" } ]
      when "linkedin"
        [ { platform: "linkedin", max_chars: 3000, style: "professional", image_size: "1200x627", image_ratio: "16:9" } ]
      else
        [ { platform: "general", max_chars: 1000, style: "adaptable", image_size: "1200x630", image_ratio: "16:9" } ]
      end
    end
  end
end
