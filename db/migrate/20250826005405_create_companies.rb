class CreateCompanies < ActiveRecord::Migration[7.2]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :subdomain
      t.string :icon

      t.timestamps
    end
    add_index :companies, :subdomain
  end
end
