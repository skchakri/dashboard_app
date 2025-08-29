class PromotionsController < ApplicationController
  layout "dashboard"
  before_action :set_product, only: [ :show, :create ]

  def show
    @user_market = current_user.market || current_company.markets.active.first
    @audience_types = [
      { id: "millennials", name: "Millennials (25-40)", description: "Tech-savvy, value-conscious, environmentally aware" },
      { id: "gen_z", name: "Gen Z (18-25)", description: "Digital natives, socially conscious, authentic" },
      { id: "gen_x", name: "Gen X (40-55)", description: "Practical, brand loyal, family-focused" },
      { id: "baby_boomers", name: "Baby Boomers (55+)", description: "Traditional, quality-focused, brand trusting" },
      { id: "professionals", name: "Young Professionals", description: "Career-focused, time-conscious, efficiency-minded" },
      { id: "parents", name: "Parents", description: "Safety-conscious, value-seeking, family-oriented" },
      { id: "students", name: "Students", description: "Budget-conscious, trend-aware, social" }
    ]

    @message_tones = [
      { id: "friendly", name: "Friendly & Warm", description: "Approachable, welcoming, like talking to a friend" },
      { id: "professional", name: "Professional", description: "Business-like, credible, authoritative" },
      { id: "exciting", name: "Exciting & Energetic", description: "Dynamic, enthusiastic, motivating" },
      { id: "luxurious", name: "Luxurious & Premium", description: "Sophisticated, exclusive, high-end" },
      { id: "casual", name: "Casual & Conversational", description: "Relaxed, natural, everyday language" },
      { id: "inspiring", name: "Inspiring & Motivational", description: "Uplifting, encouraging, aspirational" },
      { id: "humorous", name: "Humorous & Playful", description: "Fun, witty, entertaining" }
    ]

    @context_prompts = [
      { id: "seasonal_sale", name: "Seasonal Sale", prompt: "This product is part of our seasonal sale with limited-time pricing. Emphasize urgency and value." },
      { id: "new_arrival", name: "New Product Launch", prompt: "This is a brand new product we just launched. Focus on innovation and being first to market." },
      { id: "customer_favorite", name: "Customer Favorite", prompt: "This product is highly rated by customers. Include social proof and testimonials." },
      { id: "eco_friendly", name: "Eco-Friendly Focus", prompt: "Highlight the sustainable and environmentally friendly aspects of this product." },
      { id: "back_in_stock", name: "Back in Stock", prompt: "This popular product is back in stock after being sold out. Create excitement about availability." },
      { id: "bundle_offer", name: "Bundle Deal", prompt: "This product is available as part of a special bundle deal. Focus on value and savings." },
      { id: "gift_idea", name: "Perfect Gift", prompt: "Position this product as an ideal gift for someone special. Emphasize thoughtfulness." },
      { id: "professional_use", name: "Professional Quality", prompt: "Emphasize the professional-grade quality and reliability for business use." },
      { id: "lifestyle_upgrade", name: "Lifestyle Upgrade", prompt: "Show how this product can improve and elevate the customers daily life." },
      { id: "other", name: "Other (Custom)", prompt: "" }
    ]
  end

  def create
    @user_market = current_user.market || current_company.markets.active.first

    audience_type = params[:audience_type]
    message_tone = params[:message_tone]
    context_prompt = params[:context_prompt]
    custom_message = params[:custom_message]
    social_platform = params[:social_platform] || "general"

    # Build final custom message based on context selection
    final_custom_message = build_custom_message(context_prompt, custom_message)

    begin
      content_service = SocialContentGenerationService.new(
        product: @product,
        market: @user_market,
        audience_type: audience_type,
        message_tone: message_tone,
        custom_message: final_custom_message,
        social_platform: social_platform
      )

      @generated_content = content_service.generate_content
      render :result
    rescue StandardError => e
      flash[:alert] = "Failed to generate content: #{e.message}"
      redirect_to promote_product_path(@product)
    end
  end

  private

  def set_product
    @product = current_company.products.find(params[:id] || params[:product_id])
  end

  def build_custom_message(context_prompt, custom_message)
    return custom_message if context_prompt == "other" || context_prompt.blank?

    context_prompts = [
      { id: "seasonal_sale", prompt: "This product is part of our seasonal sale with limited-time pricing. Emphasize urgency and value." },
      { id: "new_arrival", prompt: "This is a brand new product we just launched. Focus on innovation and being first to market." },
      { id: "customer_favorite", prompt: "This product is highly rated by customers. Include social proof and testimonials." },
      { id: "eco_friendly", prompt: "Highlight the sustainable and environmentally friendly aspects of this product." },
      { id: "back_in_stock", prompt: "This popular product is back in stock after being sold out. Create excitement about availability." },
      { id: "bundle_offer", prompt: "This product is available as part of a special bundle deal. Focus on value and savings." },
      { id: "gift_idea", prompt: "Position this product as an ideal gift for someone special. Emphasize thoughtfulness." },
      { id: "professional_use", prompt: "Emphasize the professional-grade quality and reliability for business use." },
      { id: "lifestyle_upgrade", prompt: "Show how this product can improve and elevate the customers daily life." }
    ]

    selected_prompt = context_prompts.find { |p| p[:id] == context_prompt }
    return custom_message unless selected_prompt

    # Combine predefined prompt with custom message if provided
    if custom_message.present?
      "#{selected_prompt[:prompt]} Additional context: #{custom_message}"
    else
      selected_prompt[:prompt]
    end
  end
end
