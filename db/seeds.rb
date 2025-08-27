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