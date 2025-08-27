class CreateMarkets < ActiveRecord::Migration[7.2]
  def change
    create_table :markets do |t|
      t.string :name
      t.string :code
      t.string :currency
      t.boolean :active
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end
