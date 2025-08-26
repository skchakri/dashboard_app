class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  before_action :check_login_rate_limit, only: [:create]

  def new
    redirect_to dashboard_path if authenticated?
  end

  def create
    user = User.find_by(email: params[:email].downcase)
    
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "Welcome back!" }
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("flash_messages", 
            partial: "shared/flash", locals: { notice: "Welcome back!" })
        }
      end
    else
      respond_to do |format|
        format.html { 
          flash.now[:alert] = "Invalid email or password"
          render :new, status: :unprocessable_entity 
        }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("flash_messages", 
            partial: "shared/flash", locals: { alert: "Invalid email or password" })
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
