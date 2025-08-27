class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :sku
      t.integer :status
      t.integer :stock_quantity
      t.boolean :track_inventory
      t.boolean :featured
      t.string :base_name
      t.text :base_description
      t.decimal :base_price
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end
