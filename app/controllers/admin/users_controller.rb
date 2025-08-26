class Admin::UsersController < ApplicationController
  layout 'dashboard'
  before_action :require_admin!
  before_action :set_user, only: [:destroy]
  before_action :check_rate_limit, only: [:create, :destroy]

  def index
    @users = User.all.order(:created_at)
    @new_user = User.new
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      respond_to do |format|
        format.html { redirect_to admin_users_path, notice: "User '#{@user.email}' created successfully!" }
        format.turbo_stream { 
          flash.now[:notice] = "User '#{@user.email}' created successfully!"
          render turbo_stream: [
            turbo_stream.replace("user_form", partial: "form", locals: { user: User.new }),
            turbo_stream.replace("users_list", partial: "users_list", locals: { users: User.all.order(:created_at) }),
            turbo_stream.replace("flash_messages", partial: "shared/flash", locals: { notice: flash.now[:notice] })
          ]
        }
      end
    else
      respond_to do |format|
        format.html { 
          @users = User.all.order(:created_at)
          flash.now[:alert] = @user.errors.full_messages.join(", ")
          render :index, status: :unprocessable_entity 
        }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("user_form", partial: "form", locals: { user: @user })
        }
      end
    end
  end

  def destroy
    if @user == current_user
      respond_to do |format|
        format.html { redirect_to admin_users_path, alert: "You cannot delete your own account!" }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("flash_messages", 
            partial: "shared/flash", locals: { alert: "You cannot delete your own account!" })
        }
      end
      return
    end

    email = @user.email
    @user.destroy
    
    respond_to do |format|
      format.html { redirect_to admin_users_path, notice: "User '#{email}' deleted successfully!" }
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.remove("user_#{@user.id}"),
          turbo_stream.replace("flash_messages", 
            partial: "shared/flash", locals: { notice: "User '#{email}' deleted successfully!" })
        ]
      }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role)
  end

  def check_rate_limit
    # Simple rate limiting: max 10 user operations per minute per admin
    rate_limit_key = "admin_user_ops_#{current_user.id}"
    current_count = Rails.cache.read(rate_limit_key) || 0
    
    if current_count >= 10
      respond_to do |format|
        format.html { redirect_to admin_users_path, alert: "Rate limit exceeded. Please wait before performing more operations." }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("flash_messages", 
            partial: "shared/flash", locals: { alert: "Rate limit exceeded. Please wait before performing more operations." })
        }
      end
      return
    end

    Rails.cache.write(rate_limit_key, current_count + 1, expires_in: 1.minute)
  end
end
