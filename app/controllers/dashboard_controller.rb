class DashboardController < ApplicationController
  layout 'dashboard'
  before_action :require_admin!, only: [:admin]

  def index
    redirect_to admin_dashboard_path if current_user_admin?
  end

  def admin
    # Admin dashboard with different layout
  end
end
