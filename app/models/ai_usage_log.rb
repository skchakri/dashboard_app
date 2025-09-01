class AiUsageLog < ApplicationRecord
  belongs_to :user
  belongs_to :company

  validates :model_type, presence: true, inclusion: { in: %w[text image] }
  validates :ai_model, presence: true
  validates :cost_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :input_tokens, numericality: { greater_than_or_equal_to: 0 }
  validates :output_tokens, numericality: { greater_than_or_equal_to: 0 }

  scope :for_company, ->(company) { where(company: company) }
  scope :for_user, ->(user) { where(user: user) }
  scope :text_generation, -> { where(model_type: "text") }
  scope :image_generation, -> { where(model_type: "image") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Cost calculation helpers
  def cost_dollars
    cost_cents / 100.0
  end

  def self.total_cost_for_company(company)
    for_company(company).sum(:cost_cents) / 100.0
  end

  def self.total_cost_for_user(user)
    for_user(user).sum(:cost_cents) / 100.0
  end

  def self.usage_summary_by_user(company, limit = 50, page = 1)
    per_page = 20
    offset = (page - 1) * per_page

    select('users.email, users.id as user_id,
            COUNT(*) as total_requests,
            SUM(CASE WHEN model_type = \'text\' THEN 1 ELSE 0 END) as text_requests,
            SUM(CASE WHEN model_type = \'image\' THEN 1 ELSE 0 END) as image_requests,
            SUM(input_tokens) as total_input_tokens,
            SUM(output_tokens) as total_output_tokens,
            SUM(cost_cents) as total_cost_cents')
      .joins(:user)
      .where(company: company)
      .group("users.id, users.email")
      .order("total_cost_cents DESC")
      .limit(per_page)
      .offset(offset)
  end

  def self.usage_summary_count(company)
    joins(:user)
      .where(company: company)
      .group("users.id")
      .count
      .size
  end

  # Pricing constants (in cents per 1K tokens)
  PRICING = {
    "gpt-4o" => { input: 250, output: 1000 },           # $2.50/$10.00 per 1M tokens
    "gpt-4o-mini" => { input: 15, output: 60 },         # $0.15/$0.60 per 1M tokens
    "gpt-4-turbo" => { input: 1000, output: 3000 },     # $10.00/$30.00 per 1M tokens
    "gpt-3.5-turbo" => { input: 50, output: 150 },      # $0.50/$1.50 per 1M tokens
    "gpt-4" => { input: 3000, output: 6000 },           # $30.00/$60.00 per 1M tokens
    "dall-e-3" => { per_image: 4000 },                  # $0.040 per image (1024×1024)
    "dall-e-2" => { per_image: 2000 }                   # $0.020 per image (1024×1024)
  }.freeze

  def self.calculate_cost(model_name, input_tokens: 0, output_tokens: 0, image_count: 0)
    pricing = PRICING[model_name]
    return 0 unless pricing

    if model_name.start_with?("dall-e")
      # Image model pricing
      (pricing[:per_image] * image_count) / 100.0 # Convert to cents
    else
      # Text model pricing (per 1K tokens, converted to cents)
      input_cost = (input_tokens * pricing[:input]) / 1000.0 / 100.0
      output_cost = (output_tokens * pricing[:output]) / 1000.0 / 100.0
      ((input_cost + output_cost) * 100).round # Return in cents
    end
  end

  # Log a new usage entry
  def self.log_usage(user:, company:, model_type:, ai_model:, prompt:, response:,
                     input_tokens: 0, output_tokens: 0, request_type:, platform: nil, metadata: {})
    # Calculate cost based on model and usage
    cost_cents = if model_type == "image"
      calculate_cost(ai_model, image_count: 1) # Assume 1 image per call
    else
      calculate_cost(ai_model, input_tokens: input_tokens, output_tokens: output_tokens)
    end

    create!(
      user: user,
      company: company,
      model_type: model_type,
      ai_model: ai_model,
      prompt_text: prompt&.truncate(10000), # Limit stored prompt size
      response_text: response&.truncate(10000), # Limit stored response size
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      cost_cents: cost_cents,
      request_type: request_type,
      platform: platform,
      metadata: metadata
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log AI usage: #{e.message}"
    nil
  end
end
