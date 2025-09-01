class ImageGenerationService
  def initialize(product:, market:, audience_type:, message_tone:, user: nil)
    @product = product
    @market = market
    @audience_type = audience_type
    @message_tone = message_tone
    @user = user
    @llm_client = initialize_llm_client
    @image_model = load_configured_image_model
  end

  def generate_images_for_platform(platform_config)
    return generate_fallback_images(platform_config) if @llm_client.nil?

    # Check if image generation is disabled
    if @image_model == "disabled"
      Rails.logger.info "Image generation disabled by admin settings. Using fallback images."
      return generate_fallback_images(platform_config)
    end

    # Check if we've already detected organization verification issues
    if Rails.cache.read("openai_image_verification_required")
      Rails.logger.info "OpenAI image generation disabled (organization verification required). Using fallback images."
      return generate_fallback_images(platform_config)
    end

    # Create image prompt based on product and tone
    image_prompt = build_image_prompt(platform_config)

    images = []

    # Try to generate first image to test capability
    begin
      response = RubyLLM::Image.paint(image_prompt, model: @image_model)

      # If successful, generate all 4 images
      if response.is_a?(String) && response.start_with?("http")
        images << create_image_object(response, platform_config, 1)
        log_image_usage(image_prompt, response, platform_config) if @user
      elsif response.is_a?(Hash) && response["data"]
        image_url = response.dig("data", 0, "url")
        if image_url
          images << create_image_object(image_url, platform_config, 1)
          log_image_usage(image_prompt, image_url, platform_config) if @user
        end
      end

      # Generate remaining 3 images
      3.times do |i|
        begin
          response = RubyLLM::Image.paint(image_prompt, model: @image_model)
          if response.is_a?(String) && response.start_with?("http")
            images << create_image_object(response, platform_config, i + 2)
            log_image_usage(image_prompt, response, platform_config) if @user
          elsif response.is_a?(Hash) && response["data"]
            image_url = response.dig("data", 0, "url")
            if image_url
              images << create_image_object(image_url, platform_config, i + 2)
              log_image_usage(image_prompt, image_url, platform_config) if @user
            end
          end
        rescue StandardError => e
          Rails.logger.warn "Failed to generate additional image #{i + 2}: #{e.message}"
          images << create_fallback_image(platform_config, i + 2)
        end
      end

    rescue RubyLLM::Error => e
      if e.message.include?("organization must be verified") || e.message.include?("gpt-image-1")
        Rails.logger.info "OpenAI organization verification required for image generation. Caching this state and using fallback images."
        Rails.cache.write("openai_image_verification_required", true, expires_in: 1.hour)
        return generate_fallback_images(platform_config)
      else
        Rails.logger.error "OpenAI image generation failed: #{e.message}"
        return generate_fallback_images(platform_config)
      end
    rescue StandardError => e
      Rails.logger.error "Image generation failed: #{e.message}"
      return generate_fallback_images(platform_config)
    end

    # Ensure we always return 4 images
    while images.length < 4
      images << create_fallback_image(platform_config, images.length + 1)
    end

    images
  end

  private

  def initialize_llm_client
    api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]

    if api_key.blank?
      Rails.logger.warn "OpenAI API key not found, will use fallback images"
      return nil
    end

    # Configure RubyLLM with OpenAI
    RubyLLM.configure do |config|
      config.openai_api_key = api_key
    end

    true # Return truthy to indicate success
  end

  def load_configured_image_model
    ai_model = AiModel.find_by(company: @product.company)
    configured_model = ai_model&.image_model

    # Default to dall-e-3 if no model is configured
    configured_model || "dall-e-3"
  end

  def log_image_usage(prompt, response, platform_config)
    return unless @user

    AiUsageLog.log_usage(
      user: @user,
      company: @product.company,
      model_type: "image",
      ai_model: @image_model,
      prompt_text: prompt,
      response_text: response,
      input_tokens: 0, # Images don't have input tokens
      output_tokens: 0, # Images don't have output tokens
      request_type: "image_generation",
      platform: platform_config[:platform],
      metadata: {
        product_id: @product.id,
        market_id: @market&.id,
        audience_type: @audience_type,
        message_tone: @message_tone,
        image_size: platform_config[:image_size],
        image_ratio: platform_config[:image_ratio]
      }
    )
  end

  def build_image_prompt(platform_config)
    product_name = @product.display_name(@market)

    # Base style based on message tone
    style_description = case @message_tone
    when "luxurious" then "elegant, premium, sophisticated, high-end luxury aesthetic"
    when "exciting" then "dynamic, energetic, vibrant colors, action-oriented"
    when "friendly" then "warm, approachable, welcoming, comfortable atmosphere"
    when "professional" then "clean, modern, business-like, professional setting"
    when "humorous" then "playful, fun, creative, colorful and engaging"
    when "inspiring" then "uplifting, motivational, bright, aspirational"
    else "clean, modern, attractive"
    end

    # Platform-specific style adjustments
    platform_style = case platform_config[:platform]
    when "instagram" then "Instagram-ready, highly visual, lifestyle-focused, aesthetically pleasing"
    when "facebook" then "Facebook-optimized, engaging, community-focused, shareable"
    when "twitter" then "Twitter-friendly, attention-grabbing, concise visual message"
    when "linkedin" then "LinkedIn professional, business-focused, corporate aesthetic"
    else "social media optimized, engaging"
    end

    # Audience-specific elements
    audience_style = case @audience_type
    when "millennials", "gen_z" then "trendy, modern, tech-savvy aesthetic"
    when "professionals" then "business professional, sleek, efficient"
    when "parents" then "family-friendly, safe, trustworthy"
    when "students" then "youthful, energetic, affordable-looking"
    else "broadly appealing"
    end

    prompt = <<~PROMPT
      Create a #{style_description} product marketing image for "#{product_name}".

      Style requirements:
      - #{platform_style}
      - #{audience_style}
      - High quality, professional photography style
      - Aspect ratio: #{platform_config[:image_ratio]}
      - Include the product prominently
      - #{@product.display_description(@market)}

      The image should be suitable for #{platform_config[:platform]} social media marketing,
      targeting #{@audience_type} audience with a #{@message_tone} tone.

      Make it visually appealing, professional, and effective for driving engagement.
      No text overlays or watermarks needed.
    PROMPT

    prompt
  end

  def create_image_object(image_url, platform_config, variant_number)
    {
      id: "#{platform_config[:platform]}_#{variant_number}",
      url: image_url,
      platform: platform_config[:platform],
      size: platform_config[:image_size],
      ratio: platform_config[:image_ratio],
      variant: variant_number,
      type: "ai_generated"
    }
  end

  def generate_fallback_images(platform_config)
    4.times.map do |i|
      create_fallback_image(platform_config, i + 1)
    end
  end

  def create_fallback_image(platform_config, variant_number)
    # Use multiple stock image sources for fallback
    product_keywords = [ @product.base_name.downcase.gsub(/[^a-z0-9]/, "") ]
    product_keywords += @product.categories.pluck(:name).map { |name| name.downcase.gsub(/[^a-z0-9]/, "") }

    # Different image sources for variety and reliability
    width, height = platform_config[:image_size].split("x").map(&:to_i)

    image_sources = [
      # Lorem Picsum - simple format that always works
      {
        url: "https://picsum.photos/#{width}/#{height}",
        type: "generated_placeholder"
      },
      # Business-focused stock image from Unsplash
      {
        url: "https://images.unsplash.com/photo-1556740758-90de374c12ad?w=#{width}&h=#{height}&fit=crop&crop=center",
        type: "stock_photo"
      },
      # Professional placeholder with good colors
      {
        url: "https://via.placeholder.com/#{width}x#{height}/2563eb/ffffff?text=#{@product.base_name.slice(0, 8)}",
        type: "text_placeholder"
      },
      # Technology-focused image from Unsplash
      {
        url: "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=#{width}&h=#{height}&fit=crop&crop=center",
        type: "generic_photo"
      }
    ]

    # Cycle through different sources for variety
    source = image_sources[(variant_number - 1) % image_sources.length]

    {
      id: "#{platform_config[:platform]}_fallback_#{variant_number}",
      url: source[:url],
      platform: platform_config[:platform],
      size: platform_config[:image_size],
      ratio: platform_config[:image_ratio],
      variant: variant_number,
      type: source[:type]
    }
  end
end
