class ContentGenerationService
  def initialize(product:, market:, audience_type:, message_tone:, custom_message: nil, user: nil)
    @product = product
    @market = market
    @audience_type = audience_type
    @message_tone = message_tone
    @custom_message = custom_message
    @user = user
    @llm_client = initialize_llm_client
    @generative_model = load_configured_generative_model
  end

  def generate_content_for_platform(platform_config)
    prompt = build_prompt(platform_config)

    begin
      if @llm_client.nil?
        # No API key available, use fallback
        create_fallback_content(platform_config)
      else
        # Use RubyLLM chat interface
        chat = RubyLLM.chat
                      .with_model(@generative_model)
                      .with_temperature(0.7)

        response = chat.ask(prompt)
        # Extract content from RubyLLM::Message object
        response_text = response.respond_to?(:content) ? response.content : response.to_s

        # Log usage if user is provided
        log_usage(prompt, response_text, platform_config) if @user

        parse_response(response_text, platform_config)
      end
    rescue RubyLLM::RateLimitError => e
      Rails.logger.warn "OpenAI API rate limit exceeded for #{platform_config[:platform]}: #{e.message}"
      create_fallback_content(platform_config)
    rescue StandardError => e
      Rails.logger.error "Failed to generate content for #{platform_config[:platform]}: #{e.message}"
      # Fallback content
      create_fallback_content(platform_config)
    end
  end

  private

  def initialize_llm_client
    api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]

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

  def load_configured_generative_model
    company_key = @product.company.subdomain
    configured_model = Rails.cache.read("ai_models:#{company_key}:generative")

    # Default to gpt-4o-mini if no model is configured
    configured_model || "gpt-4o-mini"
  end

  def log_usage(prompt, response, platform_config)
    return unless @user

    # Estimate token counts (rough approximation: 1 token ≈ 4 characters)
    input_tokens = (prompt.length / 4.0).round
    output_tokens = (response.length / 4.0).round

    AiUsageLog.log_usage(
      user: @user,
      company: @product.company,
      model_type: "text",
      ai_model: @generative_model,
      prompt: prompt,
      response: response,
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      request_type: "content_generation",
      platform: platform_config[:platform],
      metadata: {
        product_id: @product.id,
        market_id: @market&.id,
        audience_type: @audience_type,
        message_tone: @message_tone
      }
    )
  end

  def build_prompt(platform_config)
    audience_descriptions = {
      "millennials" => "Tech-savvy, value-conscious, environmentally aware individuals aged 25-40",
      "gen_z" => "Digital natives, socially conscious, authentic individuals aged 18-25",
      "gen_x" => "Practical, brand loyal, family-focused individuals aged 40-55",
      "baby_boomers" => "Traditional, quality-focused, brand trusting individuals aged 55+",
      "professionals" => "Career-focused, time-conscious, efficiency-minded young professionals",
      "parents" => "Safety-conscious, value-seeking, family-oriented parents",
      "students" => "Budget-conscious, trend-aware, social students"
    }

    tone_descriptions = {
      "friendly" => "friendly, warm, and approachable like talking to a friend",
      "professional" => "professional, business-like, credible and authoritative",
      "exciting" => "exciting, energetic, dynamic and enthusiastic",
      "luxurious" => "luxurious, sophisticated, exclusive and premium",
      "casual" => "casual, conversational, relaxed with everyday language",
      "inspiring" => "inspiring, motivational, uplifting and encouraging",
      "humorous" => "humorous, playful, fun and witty"
    }

    product_details = {
      name: @product.display_name(@market),
      description: @product.display_description(@market),
      price: @product.display_price(@market),
      currency: @market&.currency || "USD",
      market: @market&.name || "General",
      sku: @product.sku,
      categories: @product.categories.pluck(:name).join(", ")
    }

    platform_instructions = case platform_config[:platform]
    when "facebook"
      "Create engaging Facebook post content that encourages comments and shares. Include a clear call-to-action."
    when "instagram"
      "Create Instagram post content that's visually appealing and hashtag-friendly. Focus on lifestyle and aesthetic appeal."
    when "twitter"
      "Create a Twitter/X post that's concise but impactful. Must be under #{platform_config[:max_chars]} characters including spaces."
    when "linkedin"
      "Create LinkedIn post content that's professional and business-focused. Emphasize value proposition and professional benefits."
    else
      "Create social media content that works across platforms."
    end

    custom_context = @custom_message.present? ? "\n\nAdditional context: #{@custom_message}" : ""

    prompt = <<~PROMPT
      You are a social media content generator creating posts for #{product_details[:name]}.

      PRODUCT DETAILS:
      Name: #{product_details[:name]}
      Description: #{product_details[:description]}
      Price: #{product_details[:currency]}#{product_details[:price]}
      Market: #{product_details[:market]}
      Categories: #{product_details[:categories]}
      SKU: #{product_details[:sku]}

      TARGET AUDIENCE: #{audience_descriptions[@audience_type] || @audience_type}
      MESSAGE TONE: #{tone_descriptions[@message_tone] || @message_tone}
      PLATFORM: #{platform_config[:platform].capitalize}
      PLATFORM REQUIREMENTS: #{platform_instructions}
      CHARACTER LIMIT: #{platform_config[:max_chars]} characters maximum

      Please provide:
      1. Main post content with HTML styling and emojis (within character limit)
      2. A compelling post title with emojis
      3. 5-8 relevant hashtags
      4. A clear call-to-action

      Content Formatting Requirements:
      - Use HTML inline tags for styling: <strong>, <em>, <span style="color: #colorcode">
      - Include relevant emojis throughout the content to make it engaging
      - Use colors that match the platform and tone (blue for professional, pink for exciting, gold for luxurious, etc.)
      - Make key phrases stand out with bold or colored text
      - Keep the HTML simple and social-media friendly

      Format your response as JSON:
      {
        "content": "HTML styled post content with <strong>bold text</strong>, <span style='color: #1e40af'>colored text</span>, and emojis 🚀✨",
        "title": "🌟 Engaging Post Title with Emojis 🎯",
        "hashtags": ["hashtag1", "hashtag2", "hashtag3", "hashtag4", "hashtag5"],
        "call_to_action": "Specific call to action with emoji 👉"
      }

      Make sure the content is engaging, authentic, and drives action while staying within the character limit. The HTML and emojis should enhance readability and visual appeal.#{custom_context}
    PROMPT

    prompt
  end

  def parse_response(response, platform_config)
    begin
      # Clean up response - remove markdown code blocks if present
      cleaned_response = response.strip
      if cleaned_response.match(/^```json\s*\n(.*)\n```$/m)
        cleaned_response = $1.strip
      elsif cleaned_response.match(/^```\s*\n(.*)\n```$/m)
        cleaned_response = $1.strip
      end

      # Try to parse JSON response
      parsed = JSON.parse(cleaned_response)

      content_text = parsed["content"] || response
      hashtags = parsed["hashtags"] || []
      title = parsed["title"] || "Post Title Here"
      call_to_action = parsed["call_to_action"]

      # Combine content with call-to-action if provided separately
      if call_to_action && !content_text.include?(call_to_action)
        content_text += "\n\n#{call_to_action}"
      end

      {
        platform: platform_config[:platform],
        content: content_text,
        title: title,
        hashtags: hashtags,
        character_count: content_text.length,
        max_chars: platform_config[:max_chars]
      }
    rescue JSON::ParserError
      # Fallback if response isn't JSON
      {
        platform: platform_config[:platform],
        content: response,
        title: "Generated Content",
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
    base_tags = [ @product.sku.downcase ]
    base_tags += @product.categories.pluck(:name).map(&:downcase)
    base_tags += [ @market&.name&.downcase ].compact
    base_tags += [ "sale", "product", "quality" ]
    base_tags.uniq.first(5)
  end

  def create_fallback_content(platform_config)
    product_name = @product.display_name(@market)
    price = "#{@market&.currency || '$'}#{@product.display_price(@market)}"

    # Add tone-based variations to fallback content
    tone_emoji = case @message_tone
    when "friendly" then "😊"
    when "exciting" then "🚀"
    when "luxurious" then "✨"
    when "humorous" then "😄"
    when "inspiring" then "💪"
    else "🌟"
    end

    audience_context = case @audience_type
    when "millennials", "gen_z" then "Perfect for your lifestyle! "
    when "professionals" then "Boost your productivity with "
    when "parents" then "Great for families - "
    when "students" then "Student-friendly and affordable - "
    else ""
    end

    # Platform-specific color schemes
    tone_colors = case @message_tone
    when "luxurious" then { primary: "#d97706", secondary: "#f59e0b" } # gold
    when "exciting" then { primary: "#dc2626", secondary: "#f97316" } # red/orange
    when "professional" then { primary: "#1e40af", secondary: "#3b82f6" } # blue
    when "friendly" then { primary: "#059669", secondary: "#10b981" } # green
    when "inspiring" then { primary: "#7c3aed", secondary: "#8b5cf6" } # purple
    else { primary: "#1f2937", secondary: "#4b5563" } # gray
    end

    fallback_content = case platform_config[:platform]
    when "twitter"
      "#{tone_emoji} <strong>#{audience_context}#{product_name}!</strong> <span style='color: #{tone_colors[:primary]}'>Quality you can trust</span> at <strong>#{price}</strong>. Perfect choice! #{tone_emoji} ##{@product.sku.downcase} #quality"
    when "instagram"
      "#{tone_emoji} <strong>#{product_name}</strong> #{tone_emoji}\n\n<em>#{audience_context}#{@product.display_description(@market)}</em>\n\n<span style='color: #{tone_colors[:primary]}'>Get yours for <strong>#{price}!</strong></span> #{tone_emoji}\n\n##{@product.sku.downcase} #quality #lifestyle #musthave"
    when "linkedin"
      "#{audience_context}Introducing <strong>#{product_name}</strong> - a <span style='color: #{tone_colors[:primary]}'>professional solution</span> that delivers quality and value.\n\n<em>#{@product.display_description(@market)}</em>\n\nAvailable now for <strong>#{price}</strong>.\n\n##{@product.sku.downcase} #business #quality #professional"
    when "facebook"
      "#{tone_emoji} <strong>Hey everyone!</strong> #{audience_context}<span style='color: #{tone_colors[:primary]}'>#{product_name}</span> is exactly what you've been looking for!\n\n<em>#{@product.display_description(@market)}</em>\n\n💰 <strong>Special price: #{price}</strong>\n\nWho else thinks this looks <span style='color: #{tone_colors[:secondary]}'>amazing</span>? Tag a friend who needs to see this! #{tone_emoji}\n\n##{@product.sku.downcase} #quality #amazing"
    else
      "#{tone_emoji} #{audience_context}Check out <strong>#{product_name}!</strong> <em>#{@product.display_description(@market)}</em> Available for <span style='color: #{tone_colors[:primary]}'>#{price}</span>. ##{@product.sku.downcase} #quality"
    end

    {
      platform: platform_config[:platform],
      content: fallback_content,
      title: "#{tone_emoji} #{product_name} - Special Offer! #{tone_emoji}",
      hashtags: generate_default_hashtags,
      character_count: fallback_content.length,
      max_chars: platform_config[:max_chars]
    }
  end
end
