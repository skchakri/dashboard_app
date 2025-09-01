class CreateAiModels < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_models do |t|
      t.references :company, null: false, foreign_key: true
      t.string :generative_model, null: false, default: "gpt-4o-mini"
      t.string :image_model, null: false, default: "dall-e-3"
      t.timestamps
    end
    # Index for company_id is already created by t.references :company
  end
end
