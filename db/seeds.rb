# Create demo companies
acme_corp = Company.find_or_create_by(subdomain: "acme") do |company|
  company.name = "ACME Corp"
end

tech_solutions = Company.find_or_create_by(subdomain: "techsolutions") do |company|
  company.name = "Tech Solutions Inc"
end

global_systems = Company.find_or_create_by(subdomain: "globalsystems") do |company|
  company.name = "Global Systems Ltd"
end

# Create users for ACME Corp
acme_admin = User.find_or_create_by(email: "admin@acme.com", company: acme_corp) do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "admin"
end

acme_user = User.find_or_create_by(email: "user@acme.com", company: acme_corp) do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "user"
end

# Create users for Tech Solutions
tech_admin = User.find_or_create_by(email: "admin@techsolutions.com", company: tech_solutions) do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "admin"
end

tech_user = User.find_or_create_by(email: "user@techsolutions.com", company: tech_solutions) do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "user"
end

# Create users for Global Systems
global_admin = User.find_or_create_by(email: "admin@globalsystems.com", company: global_systems) do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "admin"
end

global_user = User.find_or_create_by(email: "user@globalsystems.com", company: global_systems) do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "user"
end

# Create markets for companies
companies = [acme_corp, tech_solutions, global_systems]
companies.each do |company|
  # US Market
  us_market = Market.find_or_create_by(company: company, code: 'us') do |market|
    market.name = 'United States'
    market.currency = 'USD'
    market.active = true
  end

  # EU Market
  eu_market = Market.find_or_create_by(company: company, code: 'eu') do |market|
    market.name = 'European Union'
    market.currency = 'EUR'
    market.active = true
  end

  # UK Market
  uk_market = Market.find_or_create_by(company: company, code: 'uk') do |market|
    market.name = 'United Kingdom'
    market.currency = 'GBP'
    market.active = true
  end

  # Create categories
  electronics_cat = Category.find_or_create_by(company: company, name: 'Electronics') do |cat|
    cat.description = 'Electronic devices and gadgets'
  end

  accessories_cat = Category.find_or_create_by(company: company, name: 'Accessories') do |cat|
    cat.description = 'Product accessories and add-ons'
  end

  # Create sample products
  laptop_product = Product.find_or_create_by(company: company, sku: "#{company.subdomain.upcase}-LAPTOP-001") do |product|
    product.base_name = 'Professional Laptop'
    product.base_description = 'High-performance laptop for professional use with advanced features.'
    product.base_price = 1299.99
    product.status = 'active'
    product.stock_quantity = 50
    product.track_inventory = true
    product.featured = true
  end

  # Associate with categories
  laptop_product.categories << electronics_cat unless laptop_product.categories.include?(electronics_cat)

  # Create market-specific data
  ProductMarket.find_or_create_by(product: laptop_product, market: us_market) do |pm|
    pm.name = 'Professional Laptop - US Edition'
    pm.description = 'High-performance laptop designed for US professionals with advanced features and local support.'
    pm.price = 1299.99
    pm.available = true
  end

  ProductMarket.find_or_create_by(product: laptop_product, market: eu_market) do |pm|
    pm.name = 'Professional Laptop - EU Edition'
    pm.description = 'High-performance laptop designed for European professionals with GDPR compliance and multilingual support.'
    pm.price = 1199.99
    pm.available = true
    pm.special_price = 999.99
    pm.special_price_start = Date.current
    pm.special_price_end = Date.current + 30.days
  end

  # Create product images
  ProductImage.find_or_create_by(product: laptop_product, sort_order: 1) do |img|
    img.image_url = 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400'
    img.alt_text = 'Professional laptop front view'
  end

  # Create product keywords
  ['laptop', 'professional', 'business', 'computer', 'portable'].each do |keyword|
    ProductKeyword.find_or_create_by(product: laptop_product, keyword: keyword)
  end

  # Set user markets (assign users to US market by default)
  company.users.where(market: nil).update_all(market_id: us_market.id)
end

puts "Created #{Company.count} companies:"
puts "- ACME Corp (subdomain: acme)"
puts "- Tech Solutions Inc (subdomain: techsolutions)" 
puts "- Global Systems Ltd (subdomain: globalsystems)"
puts ""
puts "Created #{User.count} users across all companies"
puts ""
puts "Demo Login URLs:"
puts "- http://acme.localhost:3000/login"
puts "- http://techsolutions.localhost:3000/login"
puts "- http://globalsystems.localhost:3000/login"
puts ""
puts "Login credentials for each company:"
puts "Admin: admin@[company].com"
puts "User: user@[company].com"
puts "Password for all: password123"