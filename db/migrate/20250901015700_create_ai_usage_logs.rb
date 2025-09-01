class CreateAiUsageLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_usage_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :model_type, null: false # 'text' or 'image'
      t.string :ai_model, null: false # 'gpt-4o', 'dall-e-3', etc.
      t.text :prompt_text
      t.text :response_text
      t.integer :input_tokens, default: 0
      t.integer :output_tokens, default: 0
      t.integer :cost_cents, null: false, default: 0
      t.string :request_type # 'content_generation', 'image_generation'
      t.string :platform # 'facebook', 'instagram', etc.
      t.json :metadata # Store additional context like product_id, market_id, etc.

      t.timestamps
    end

    # Add indexes for efficient querying
    add_index :ai_usage_logs, [ :company_id, :created_at ]
    add_index :ai_usage_logs, [ :user_id, :created_at ]
    add_index :ai_usage_logs, [ :model_type, :created_at ]
    add_index :ai_usage_logs, :created_at
  end
end
