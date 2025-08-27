class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Disabled in development to avoid compatibility issues
  allow_browser versions: :modern unless Rails.env.development?

  before_action :set_current_company
  before_action :authenticate_user!

  private

  def set_current_company
    # debugger
    subdomain = request.subdomain
    puts "=== SIMPLE DEBUG: Subdomain is '#{subdomain}' from host '#{request.host}'"
    Rails.logger.debug "=== DEBUG: Subdomain detected: #{subdomain.inspect}"
    Rails.logger.debug "=== DEBUG: Full host: #{request.host}"
    Rails.logger.debug "=== DEBUG: Domain: #{request.domain}"

    if subdomain.present?
      @current_company = Company.find_by_subdomain(subdomain)
      Rails.logger.debug "=== DEBUG: Company found: #{@current_company&.name}"
      redirect_to root_url(subdomain: false) unless @current_company
    else
      @current_company = nil
      Rails.logger.debug "=== DEBUG: No subdomain, setting company to nil"
    end
  end

  def current_company
    @current_company
  end
  helper_method :current_company

  def current_user
    return nil unless session[:user_id] && current_company
    @current_user ||= current_company.users.find_by(id: session[:user_id])
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
