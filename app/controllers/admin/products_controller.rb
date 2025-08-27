class Admin::ProductsController < ApplicationController
  layout 'dashboard'
  
  before_action :require_admin!
  before_action :set_target_company
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  
  def index
    @products = @target_company.products.includes(:categories, :markets)
  end
  
  def new
    @product = @target_company.products.build
  end
  
  def create
    @product = @target_company.products.build(product_params)
    
    if @product.save
      redirect_to admin_products_path, notice: "Product created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
    @markets = @target_company.markets.active
    @selected_market = params[:market_id].present? ? @target_company.markets.find(params[:market_id]) : nil
  end
  
  def edit
  end
  
  def update
    if @product.update(product_params)
      redirect_to admin_product_path(@product), notice: "Product updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @product.destroy
    redirect_to admin_products_path, notice: "Product deleted successfully."
  end
  
  def upload
    # Show upload form
  end
  
  def import
    unless params[:json_file].present?
      redirect_to upload_admin_products_path, alert: "Please select a JSON file."
      return
    end
    
    begin
      file_content = params[:json_file].read
      products_data = JSON.parse(file_content)
      
      imported_count = 0
      errors = []
      
      products_data.each_with_index do |product_data, index|
        result = ProductImportService.new(@target_company, product_data).call
        if result[:success]
          imported_count += 1
        else
          errors << "Product #{index + 1}: #{result[:errors].join(', ')}"
        end
      end
      
      if errors.empty?
        redirect_to admin_products_path, notice: "Successfully imported #{imported_count} products."
      else
        flash[:notice] = "Imported #{imported_count} products." if imported_count > 0
        flash[:alert] = "Errors: #{errors.join('; ')}"
        redirect_to upload_admin_products_path
      end
      
    rescue JSON::ParserError => e
      redirect_to upload_admin_products_path, alert: "Invalid JSON file: #{e.message}"
    rescue StandardError => e
      redirect_to upload_admin_products_path, alert: "Import failed: #{e.message}"
    end
  end
  
  private
  
  def set_target_company
    if current_company&.subdomain == 'default'
      # Default admin can select company
      @target_company = params[:company_id].present? ? Company.find(params[:company_id]) : nil
      @companies = Company.where.not(subdomain: 'default')
    else
      # Company-specific admin
      @target_company = current_company
    end
    
    unless @target_company
      redirect_to admin_products_path, alert: "Please select a company."
    end
  end
  
  def set_product
    @product = @target_company.products.find(params[:id])
  end
  
  def product_params
    params.require(:product).permit(
      :sku, :status, :stock_quantity, :track_inventory, :featured,
      :base_name, :base_description, :base_price,
      category_ids: [],
      product_keywords_attributes: [:id, :keyword, :_destroy],
      product_images_attributes: [:id, :alt_text, :sort_order, :image, :_destroy],
      product_markets_attributes: [:id, :market_id, :name, :description, :price, :available, :special_price, :special_price_start, :special_price_end, :_destroy]
    )
  end
end
