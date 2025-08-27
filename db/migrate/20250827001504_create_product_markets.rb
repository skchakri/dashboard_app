class CreateProductMarkets < ActiveRecord::Migration[7.2]
  def change
    create_table :product_markets do |t|
      t.references :product, null: false, foreign_key: true
      t.references :market, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.decimal :price
      t.boolean :available
      t.decimal :special_price
      t.date :special_price_start
      t.date :special_price_end

      t.timestamps
    end
  end
end
