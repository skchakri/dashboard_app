class Admin::CostReportsController < ApplicationController
  layout "dashboard"

  before_action :require_admin!
  before_action :set_target_company

  def index
    redirect_to admin_cost_reports_path, alert: "Please select a company." unless @target_company
    return unless @target_company

    @page = params[:page]&.to_i || 1
    @date_range = params[:date_range] || "30_days"

    # Calculate date range
    @start_date, @end_date = calculate_date_range(@date_range)

    # Get usage summary by user with pagination
    @usage_data = AiUsageLog.usage_summary_by_user(@target_company, 50, @page)
    @total_users = AiUsageLog.usage_summary_count(@target_company)
    @total_pages = (@total_users / 20.0).ceil

    # Calculate totals for the company
    scoped_logs = AiUsageLog.for_company(@target_company).by_date_range(@start_date, @end_date)
    @company_totals = {
      total_cost: scoped_logs.sum(:cost_cents) / 100.0,
      total_requests: scoped_logs.count,
      text_requests: scoped_logs.text_generation.count,
      image_requests: scoped_logs.image_generation.count,
      total_input_tokens: scoped_logs.sum(:input_tokens),
      total_output_tokens: scoped_logs.sum(:output_tokens)
    }

    # Get model usage breakdown
    @model_usage = scoped_logs
      .group(:ai_model)
      .group(:model_type)
      .select("ai_model, model_type, COUNT(*) as request_count, SUM(cost_cents) as total_cost_cents")
      .order("total_cost_cents DESC")

    # Get daily usage for the past 30 days (for chart)
    @daily_usage = scoped_logs
      .where("created_at >= ?", 30.days.ago)
      .group("DATE(created_at)")
      .select("DATE(created_at) as date, COUNT(*) as request_count, SUM(cost_cents) as cost_cents")
      .order("date DESC")
      .limit(30)
  end

  def user_details
    @user = User.find(params[:user_id])
    redirect_to admin_cost_reports_path, alert: "User not found." unless @user
    return unless @user

    unless @user.company == @target_company
      redirect_to admin_cost_reports_path, alert: "User not found in selected company."
      return
    end

    @page = params[:page]&.to_i || 1
    per_page = 50
    offset = (@page - 1) * per_page

    @date_range = params[:date_range] || "30_days"
    @start_date, @end_date = calculate_date_range(@date_range)

    # Get user's usage logs with pagination
    @usage_logs = AiUsageLog.for_user(@user)
      .by_date_range(@start_date, @end_date)
      .recent
      .limit(per_page)
      .offset(offset)
      .includes(:company)

    @total_logs = AiUsageLog.for_user(@user).by_date_range(@start_date, @end_date).count
    @total_pages = (@total_logs / per_page.to_f).ceil

    # Calculate user totals
    user_logs = AiUsageLog.for_user(@user).by_date_range(@start_date, @end_date)
    @user_totals = {
      total_cost: user_logs.sum(:cost_cents) / 100.0,
      total_requests: user_logs.count,
      text_requests: user_logs.text_generation.count,
      image_requests: user_logs.image_generation.count,
      total_input_tokens: user_logs.sum(:input_tokens),
      total_output_tokens: user_logs.sum(:output_tokens)
    }
  end

  def export
    redirect_to admin_cost_reports_path, alert: "Please select a company." unless @target_company
    return unless @target_company

    @date_range = params[:date_range] || "30_days"
    @start_date, @end_date = calculate_date_range(@date_range)

    # Get all usage data for export
    @usage_data = AiUsageLog.for_company(@target_company)
      .by_date_range(@start_date, @end_date)
      .includes(:user)
      .recent

    respond_to do |format|
      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"ai_usage_report_#{@target_company.subdomain}_#{Date.current}.csv\""
        headers["Content-Type"] = "text/csv"
      end
    end
  end

  private

  def set_target_company
    if current_company&.subdomain == "default"
      # Default admin can select company
      @target_company = params[:company_id].present? ? Company.find(params[:company_id]) : nil
      @companies = Company.where.not(subdomain: "default")
    else
      # Company-specific admin
      @target_company = current_company
    end
  end

  def calculate_date_range(range)
    case range
    when "7_days"
      [ 7.days.ago, Time.current ]
    when "30_days"
      [ 30.days.ago, Time.current ]
    when "90_days"
      [ 90.days.ago, Time.current ]
    when "current_month"
      [ Time.current.beginning_of_month, Time.current ]
    when "last_month"
      [ 1.month.ago.beginning_of_month, 1.month.ago.end_of_month ]
    else
      [ 30.days.ago, Time.current ]
    end
  end
end
