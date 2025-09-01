class Admin::AiModelsController < ApplicationController
  layout "dashboard"

  before_action :require_admin!
  before_action :set_target_company

  def index
    # Load current settings or set defaults
    @current_settings = load_ai_model_settings
    @generative_models = available_generative_models
    @image_models = available_image_models
  end

  def update
    settings = ai_model_params

    # Validate model selections
    if valid_model_selection?(settings)
      save_ai_model_settings(settings)
      redirect_to admin_ai_models_path, notice: "AI model settings updated successfully."
    else
      flash[:alert] = "Invalid model selection. Please choose valid models."
      redirect_to admin_ai_models_path
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

    unless @target_company
      redirect_to admin_ai_models_path, alert: "Please select a company."
    end
  end

  def load_ai_model_settings
    ai_model = AiModel.find_by(company: @target_company)
    {
      generative_model: ai_model&.generative_model || "gpt-4o-mini",
      image_model: ai_model&.image_model || "dall-e-3"
    }
  end

  def save_ai_model_settings(settings)
    company_key = @target_company&.subdomain || "default"

    ai_model = AiModel.find_or_initialize_by(company: @target_company)
    ai_model.generative_model = settings[:generative_model]
    ai_model.image_model = settings[:image_model]
    ai_model.save!

    Rails.logger.info "AI model settings updated for #{company_key}: #{settings}"
  end

  def available_generative_models
    [
      { id: "gpt-4o", name: "GPT-4o", description: "Latest GPT-4 Omni model - most capable, higher cost" },
      { id: "gpt-4o-mini", name: "GPT-4o Mini", description: "Faster and cheaper GPT-4 model - good balance" },
      { id: "gpt-4-turbo", name: "GPT-4 Turbo", description: "Previous generation GPT-4 - reliable" },
      { id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", description: "Fast and cost-effective - basic content generation" },
      { id: "gpt-4", name: "GPT-4", description: "Original GPT-4 - highest quality but slower" }
    ]
  end

  def available_image_models
    [
      { id: "imagen-3.0-generate-002", name: "imagen-3.0-generate-002", description: "Latest image model - highest quality, more expensive" },
      { id: "gpt-image-1", name: "gpt-image-1", description: "Latest image model - highest quality, more expensive" },
      { id: "dall-e-3", name: "DALL-E 3", description: "Latest image model - highest quality, more expensive" },
      { id: "dall-e-2", name: "DALL-E 2", description: "Previous generation - good quality, lower cost" },
      { id: "disabled", name: "Disabled", description: "Use fallback images only - no AI generation" }
    ]
  end

  def valid_model_selection?(settings)
    generative_ids = available_generative_models.map { |m| m[:id] }
    image_ids = available_image_models.map { |m| m[:id] }

    generative_ids.include?(settings[:generative_model]) &&
    image_ids.include?(settings[:image_model])
  end

  def ai_model_params
    # Handle the bracketed parameter name that comes from fields_for
    (params["[ai_models]"] || params[:ai_models]).permit(:generative_model, :image_model, :company_id)
  end
end
