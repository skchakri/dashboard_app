# Create admin user
admin = User.find_or_create_by(email: "admin@dashboard.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "admin"
end

# Create regular user
regular_user = User.find_or_create_by(email: "user@dashboard.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = "user"
end

puts "Created #{User.count} users"
puts "Admin: admin@dashboard.com"
puts "User: user@dashboard.com"
puts "Password for both: password123"