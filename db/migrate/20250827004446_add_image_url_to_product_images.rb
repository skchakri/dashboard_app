class AddImageUrlToProductImages < ActiveRecord::Migration[7.2]
  def change
    add_column :product_images, :image_url, :string
  end
end
