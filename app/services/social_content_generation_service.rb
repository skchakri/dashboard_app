class SocialContentGenerationService
  def initialize(product:, market:, audience_type:, message_tone:, custom_message: nil, social_platform: 'general')
    @product = product
    @market = market
    @audience_type = audience_type
    @message_tone = message_tone
    @custom_message = custom_message
    @social_platform = social_platform
    @llm_client = initialize_llm_client
  end

  def generate_content
    platform_configs = get_platform_configs
    generated_contents = []

    platform_configs.each do |platform_config|
      prompt = build_prompt(platform_config)
      
      begin
        if @llm_client.nil?
          # No API key available, use fallback
          generated_contents << create_fallback_content(platform_config)
        else
          # Use RubyLLM chat interface
          chat = RubyLLM.chat
                        .with_model('gpt-3.5-turbo')
                        .with_temperature(0.7)
          
          response = chat.ask(prompt)
          content = parse_response(response, platform_config)
          
          # Generate images for the platform
          content[:images] = generate_images_for_platform(platform_config)
          
          generated_contents << content
        end
      rescue RubyLLM::RateLimitError => e
        Rails.logger.warn "OpenAI API rate limit exceeded for #{platform_config[:platform]}: #{e.message}"
        generated_contents << create_fallback_content(platform_config)
      rescue StandardError => e
        Rails.logger.error "Failed to generate content for #{platform_config[:platform]}: #{e.message}"
        # Fallback content
        generated_contents << create_fallback_content(platform_config)
      end
    end

    generated_contents
  end

  private

  def initialize_llm_client
    api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV['OPENAI_API_KEY']
    
    if api_key.blank?
      Rails.logger.warn "OpenAI API key not found, will use fallback content"
      return nil
    end
    
    # Configure RubyLLM with OpenAI
    RubyLLM.configure do |config|
      config.openai_api_key = api_key
    end
    
    true # Return truthy to indicate success
  end

  def get_platform_configs
    if @social_platform == 'general'
      [
        { platform: 'facebook', max_chars: 2200, style: 'conversational', image_size: '1200x630', image_ratio: '16:9' },
        { platform: 'instagram', max_chars: 2200, style: 'visual', image_size: '1080x1080', image_ratio: '1:1' },
        { platform: 'twitter', max_chars: 280, style: 'concise', image_size: '1200x675', image_ratio: '16:9' },
        { platform: 'linkedin', max_chars: 3000, style: 'professional', image_size: '1200x627', image_ratio: '16:9' }
      ]
    else
      case @social_platform
      when 'facebook'
        [{ platform: 'facebook', max_chars: 2200, style: 'conversational', image_size: '1200x630', image_ratio: '16:9' }]
      when 'instagram'
        [{ platform: 'instagram', max_chars: 2200, style: 'visual', image_size: '1080x1080', image_ratio: '1:1' }]
      when 'twitter'
        [{ platform: 'twitter', max_chars: 280, style: 'concise', image_size: '1200x675', image_ratio: '16:9' }]
      when 'linkedin'
        [{ platform: 'linkedin', max_chars: 3000, style: 'professional', image_size: '1200x627', image_ratio: '16:9' }]
      else
        [{ platform: 'general', max_chars: 1000, style: 'adaptable', image_size: '1200x630', image_ratio: '16:9' }]
      end
    end
  end

  def build_prompt(platform_config)
    audience_descriptions = {
      'millennials' => 'Tech-savvy, value-conscious, environmentally aware individuals aged 25-40',
      'gen_z' => 'Digital natives, socially conscious, authentic individuals aged 18-25',
      'gen_x' => 'Practical, brand loyal, family-focused individuals aged 40-55',
      'baby_boomers' => 'Traditional, quality-focused, brand trusting individuals aged 55+',
      'professionals' => 'Career-focused, time-conscious, efficiency-minded young professionals',
      'parents' => 'Safety-conscious, value-seeking, family-oriented parents',
      'students' => 'Budget-conscious, trend-aware, social students'
    }

    tone_descriptions = {
      'friendly' => 'friendly, warm, and approachable like talking to a friend',
      'professional' => 'professional, business-like, credible and authoritative',
      'exciting' => 'exciting, energetic, dynamic and enthusiastic',
      'luxurious' => 'luxurious, sophisticated, exclusive and premium',
      'casual' => 'casual, conversational, relaxed with everyday language',
      'inspiring' => 'inspiring, motivational, uplifting and encouraging',
      'humorous' => 'humorous, playful, fun and witty'
    }

    product_details = {
      name: @product.display_name(@market),
      description: @product.display_description(@market),
      price: @product.display_price(@market),
      currency: @market&.currency || 'USD',
      market: @market&.name || 'General',
      sku: @product.sku,
      categories: @product.categories.pluck(:name).join(', ')
    }

    platform_instructions = case platform_config[:platform]
    when 'facebook'
      "Create engaging Facebook post content that encourages comments and shares. Include a clear call-to-action."
    when 'instagram'
      "Create Instagram post content that's visually appealing and hashtag-friendly. Focus on lifestyle and aesthetic appeal."
    when 'twitter'
      "Create a Twitter/X post that's concise but impactful. Must be under #{platform_config[:max_chars]} characters including spaces."
    when 'linkedin'
      "Create LinkedIn post content that's professional and business-focused. Emphasize value proposition and professional benefits."
    else
      "Create social media content that works across platforms."
    end

    custom_context = @custom_message.present? ? "\n\nAdditional context: #{@custom_message}" : ""

    prompt = <<~PROMPT
      You are a professional social media content creator. Create compelling promotional content for the following product:

      PRODUCT DETAILS:
      - Product Name: #{product_details[:name]}
      - Description: #{product_details[:description]}
      - Price: #{product_details[:currency]}#{product_details[:price]}
      - Market: #{product_details[:market]}
      - Categories: #{product_details[:categories]}
      #{custom_context}

      TARGET AUDIENCE: #{audience_descriptions[@audience_type]}

      MESSAGE TONE: Write in a #{tone_descriptions[@message_tone]} tone.

      PLATFORM: #{platform_config[:platform].capitalize}
      PLATFORM REQUIREMENTS: #{platform_instructions}
      CHARACTER LIMIT: #{platform_config[:max_chars]} characters maximum

      Please provide:
      1. Main post content (within character limit)
      2. 5-8 relevant hashtags
      3. A clear call-to-action

      Format your response as JSON:
      {
        "content": "Main post content here",
        "hashtags": ["hashtag1", "hashtag2", "hashtag3", "hashtag4", "hashtag5"],
        "call_to_action": "Specific call to action"
      }

      Make sure the content is engaging, authentic, and drives action while staying within the character limit.
    PROMPT

    prompt
  end

  def parse_response(response, platform_config)
    begin
      # Try to parse JSON response
      parsed = JSON.parse(response)
      
      content_text = parsed['content'] || response
      hashtags = parsed['hashtags'] || []
      call_to_action = parsed['call_to_action']

      # Combine content with call-to-action if provided separately
      if call_to_action && !content_text.include?(call_to_action)
        content_text += "\n\n#{call_to_action}"
      end

      {
        platform: platform_config[:platform],
        content: content_text,
        hashtags: hashtags,
        character_count: content_text.length,
        max_chars: platform_config[:max_chars]
      }
    rescue JSON::ParserError
      # Fallback if response isn't JSON
      {
        platform: platform_config[:platform],
        content: response.strip,
        hashtags: extract_hashtags_from_text(response),
        character_count: response.length,
        max_chars: platform_config[:max_chars]
      }
    end
  end

  def extract_hashtags_from_text(text)
    # Extract hashtags from text using regex
    hashtags = text.scan(/#(\w+)/).flatten
    hashtags.empty? ? generate_default_hashtags : hashtags
  end

  def generate_default_hashtags
    base_tags = [@product.sku.downcase]
    base_tags += @product.categories.pluck(:name).map(&:downcase)
    base_tags += [@market&.name&.downcase].compact
    base_tags += ['sale', 'product', 'quality']
    base_tags.uniq.first(5)
  end

  def create_fallback_content(platform_config)
    product_name = @product.display_name(@market)
    price = "#{@market&.currency || '$'}#{@product.display_price(@market)}"
    
    # Add tone-based variations to fallback content
    tone_emoji = case @message_tone
    when 'friendly' then '😊'
    when 'exciting' then '🚀'
    when 'luxurious' then '✨'
    when 'humorous' then '😄'
    when 'inspiring' then '💪'
    else '🌟'
    end
    
    audience_context = case @audience_type
    when 'millennials', 'gen_z' then 'Perfect for your lifestyle! '
    when 'professionals' then 'Boost your productivity with '
    when 'parents' then 'Great for families - '
    when 'students' then 'Student-friendly and affordable - '
    else ''
    end
    
    fallback_content = case platform_config[:platform]
    when 'twitter'
      "#{tone_emoji} #{audience_context}#{product_name}! Quality you can trust at #{price}. Perfect choice! ##{@product.sku.downcase} #quality"
    when 'instagram'
      "#{tone_emoji} #{product_name} #{tone_emoji}\n\n#{audience_context}#{@product.display_description(@market)}\n\nGet yours for #{price}! #{tone_emoji}\n\n##{@product.sku.downcase} #quality #lifestyle #musthave"
    when 'linkedin'
      "#{audience_context}Introducing #{product_name} - a professional solution that delivers quality and value.\n\n#{@product.display_description(@market)}\n\nAvailable now for #{price}.\n\n##{@product.sku.downcase} #business #quality #professional"
    when 'facebook'
      "#{tone_emoji} Hey everyone! #{audience_context}#{product_name} is exactly what you've been looking for!\n\n#{@product.display_description(@market)}\n\n💰 Special price: #{price}\n\nWho else thinks this looks amazing? Tag a friend who needs to see this! #{tone_emoji}\n\n##{@product.sku.downcase} #quality #amazing"
    else
      "#{tone_emoji} #{audience_context}Check out #{product_name}! #{@product.display_description(@market)} Available for #{price}. ##{@product.sku.downcase} #quality"
    end

    {
      platform: platform_config[:platform],
      content: fallback_content,
      hashtags: generate_default_hashtags,
      character_count: fallback_content.length,
      max_chars: platform_config[:max_chars],
      images: generate_fallback_images(platform_config)
    }
  end

  def generate_images_for_platform(platform_config)
    return generate_fallback_images(platform_config) if @llm_client.nil?

    # Create image prompt based on product and tone
    image_prompt = build_image_prompt(platform_config)
    
    images = []
    4.times do |i|
      begin
        # Use RubyLLM Image.paint for DALL-E image generation
        response = RubyLLM::Image.paint(image_prompt)
        
        if response.is_a?(String) && response.start_with?('http')
          # Direct URL response
          images << create_image_object(response, platform_config, i + 1)
        elsif response.is_a?(Hash) && response['data']
          # OpenAI API response format
          image_url = response.dig('data', 0, 'url')
          images << create_image_object(image_url, platform_config, i + 1) if image_url
        elsif response.respond_to?(:dig)
          # Try different response formats
          image_url = response.dig('url') || response.dig('image_url') || response.dig('data', 0, 'url')
          images << create_image_object(image_url, platform_config, i + 1) if image_url
        end
      rescue StandardError => e
        Rails.logger.error "Failed to generate image #{i + 1} for #{platform_config[:platform]}: #{e.message}"
        # Add fallback image for failed generations
        images << create_fallback_image(platform_config, i + 1)
      end
    end
    
    # Ensure we always return 4 images
    while images.length < 4
      images << create_fallback_image(platform_config, images.length + 1)
    end
    
    images
  end

  def generate_fallback_images(platform_config)
    4.times.map do |i|
      create_fallback_image(platform_config, i + 1)
    end
  end

  def build_image_prompt(platform_config)
    product_name = @product.display_name(@market)
    
    # Base style based on message tone
    style_description = case @message_tone
    when 'luxurious' then 'elegant, premium, sophisticated, high-end luxury aesthetic'
    when 'exciting' then 'dynamic, energetic, vibrant colors, action-oriented'
    when 'friendly' then 'warm, approachable, welcoming, comfortable atmosphere'
    when 'professional' then 'clean, modern, business-like, professional setting'
    when 'humorous' then 'playful, fun, creative, colorful and engaging'
    when 'inspiring' then 'uplifting, motivational, bright, aspirational'
    else 'clean, modern, attractive'
    end

    # Platform-specific style adjustments
    platform_style = case platform_config[:platform]
    when 'instagram' then 'Instagram-ready, highly visual, lifestyle-focused, aesthetically pleasing'
    when 'facebook' then 'Facebook-optimized, engaging, community-focused, shareable'
    when 'twitter' then 'Twitter-friendly, attention-grabbing, concise visual message'
    when 'linkedin' then 'LinkedIn professional, business-focused, corporate aesthetic'
    else 'social media optimized, engaging'
    end

    # Audience-specific elements
    audience_style = case @audience_type
    when 'millennials', 'gen_z' then 'trendy, modern, tech-savvy aesthetic'
    when 'professionals' then 'business professional, sleek, efficient'
    when 'parents' then 'family-friendly, safe, trustworthy'
    when 'students' then 'youthful, energetic, affordable-looking'
    else 'broadly appealing'
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

      Visual elements to include:
      - Clean background that complements the product
      - Professional lighting
      - Marketing-ready composition
      - No text overlay (text will be added separately)
      - Focus on product appeal and #{@message_tone} mood

      Additional context: #{@custom_message}

      Create a compelling visual that would make people want to learn more about this product.
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
      type: 'ai_generated'
    }
  end

  def create_fallback_image(platform_config, variant_number)
    # Use multiple stock image sources for fallback
    product_keywords = [@product.base_name.downcase.gsub(/[^a-z0-9]/, '')]
    product_keywords += @product.categories.pluck(:name).map { |name| name.downcase.gsub(/[^a-z0-9]/, '') }
    search_term = (product_keywords.first || 'product').slice(0, 20) # Limit length
    
    # Different image sources for variety and reliability
    width, height = platform_config[:image_size].split('x').map(&:to_i)
    
    image_sources = [
      # Lorem Picsum - simple format that always works
      {
        url: "https://picsum.photos/#{width}/#{height}",
        type: 'generated_placeholder'
      },
      # Business-focused stock image from Unsplash
      {
        url: "https://images.unsplash.com/photo-1556740758-90de374c12ad?w=#{width}&h=#{height}&fit=crop&crop=center",
        type: 'stock_photo'
      },
      # Professional placeholder with good colors
      {
        url: "https://via.placeholder.com/#{width}x#{height}/2563eb/ffffff?text=#{@product.base_name.slice(0,8)}",
        type: 'text_placeholder'
      },
      # Technology-focused image from Unsplash
      {
        url: "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=#{width}&h=#{height}&fit=crop&crop=center",
        type: 'generic_photo'
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