class DashboardController < ApplicationController
  layout "dashboard"
  before_action :require_admin!, only: [ :admin ]

  def index
    redirect_to admin_dashboard_path if current_user_admin?

    @user_market = current_user.market || current_company.markets.active.first
    @products = if @user_market
      current_company.products.joins(:product_markets)
                     .where(product_markets: { market: @user_market, available: true })
                     .where(status: :active)
                     .includes(:product_markets, :categories, :product_images)
                     .distinct
    else
      current_company.products.where(status: :active)
                     .includes(:categories, :product_images)
    end

    # Example: Synchronously generate content for first product
    if @products.any?
      # Define default platform config if not provided
      platform_config = params[:platform_config] || {
        platform: "instagram",
        max_chars: 2200,
        image_size: "1080x1080",
        image_ratio: "1:1"
      }

      @content = ContentGenerationService.new(
        product: @products.first,
        market: @user_market,
        audience_type: params[:audience_type] || "millennials",
        message_tone: params[:message_tone] || "friendly",
        custom_message: params[:custom_message],
        user: current_user
      ).generate_content_for_platform(platform_config)

      # Start image generation in background
      @image_status = "pending"
      @image_url = nil
      ImageGenerationJob.perform_later(@products.first.id, @user_market.id, current_user.id)
    end
  end

  def image_status
    image = ProductImage.find_by(product_id: params[:product_id], market_id: params[:market_id])
    if image&.ready?
      render json: { status: "ready", url: image.url }
    else
      render json: { status: "pending" }
    end
  end

  def admin
    # Admin dashboard with different layout
  end
end
