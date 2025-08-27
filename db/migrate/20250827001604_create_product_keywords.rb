class CreateProductKeywords < ActiveRecord::Migration[7.2]
  def change
    create_table :product_keywords do |t|
      t.references :product, null: false, foreign_key: true
      t.string :keyword

      t.timestamps
    end
  end
end
