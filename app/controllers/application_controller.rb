class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Disabled in development to avoid compatibility issues
  allow_browser versions: :modern unless Rails.env.development?

  before_action :authenticate_user!

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def authenticated?
    !!current_user
  end
  helper_method :authenticated?

  def authenticate_user!
    redirect_to login_path unless authenticated?
  end

  def current_user_admin?
    current_user&.admin?
  end
  helper_method :current_user_admin?

  def require_admin!
    redirect_to dashboard_path unless current_user_admin?
  end
end
