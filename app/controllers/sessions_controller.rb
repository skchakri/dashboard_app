class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  # skip_before_action :set_current_company, only: [ :new, :create ], if: -> { request.subdomain.blank? }
  before_action :check_login_rate_limit, only: [ :create ]

  def new
    redirect_to dashboard_path if authenticated?
    # Load companies when accessed from main domain (no subdomain)
    @companies = Company.all if request.subdomain.blank?
  end

  def create
    company = current_company || (params[:company_id] && Company.find_by(id: params[:company_id]))
    return handle_no_company_or_selection unless company

    user = company.users.find_by(email: params[:email].downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id

      # If no current_company (main domain), redirect to company subdomain
      if current_company
        respond_to do |format|
          format.html { redirect_to dashboard_path, notice: "Welcome back!" }
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace("flash_messages",
              partial: "shared/flash", locals: { notice: "Welcome back!" })
          }
        end
      else
        # Redirect to company subdomain with user logged in
        # Session will work across subdomains with domain: :all configuration
        redirect_to "http://#{company.subdomain}.localhost:3000/dashboard", notice: "Welcome back!", allow_other_host: true
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:alert] = "Invalid email or password for this company"
          render :new, status: :unprocessable_entity
        }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("flash_messages",
            partial: "shared/flash", locals: { alert: "Invalid email or password for this company" })
        }
      end
    end
  end

  def destroy
    session.delete(:user_id)
    @current_user = nil
    redirect_to login_path, notice: "Logged out successfully"
  end

  private

  def handle_no_company_or_selection
    respond_to do |format|
      format.html {
        flash.now[:alert] = current_company ? "Company not found. Please check your URL." : "Please select a company to continue."
        render :new, status: current_company ? :not_found : :unprocessable_entity
      }
      format.turbo_stream {
        alert_message = current_company ? "Company not found. Please check your URL." : "Please select a company to continue."
        render turbo_stream: turbo_stream.replace("flash_messages",
          partial: "shared/flash", locals: { alert: alert_message })
      }
    end
  end

  def check_login_rate_limit
    # Rate limit: max 5 login attempts per IP per minute
    ip = request.remote_ip
    rate_limit_key = "login_attempts_#{ip}"
    current_count = Rails.cache.read(rate_limit_key) || 0

    if current_count >= 5
      respond_to do |format|
        format.html {
          flash.now[:alert] = "Too many login attempts. Please wait before trying again."
          render :new, status: :too_many_requests
        }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("flash_messages",
            partial: "shared/flash", locals: { alert: "Too many login attempts. Please wait before trying again." })
        }
      end
      return
    end

    Rails.cache.write(rate_limit_key, current_count + 1, expires_in: 1.minute)
  end
end
