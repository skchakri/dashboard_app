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
  end

  def admin
    # Admin dashboard with different layout
  end
end
