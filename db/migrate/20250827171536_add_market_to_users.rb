class AddMarketToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :market, null: true, foreign_key: true
  end
end
