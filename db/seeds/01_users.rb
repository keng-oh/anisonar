User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password"
  u.role = :admin
end

User.find_or_create_by!(email: "user@example.com") do |u|
  u.password = "password"
  u.role = :general
end
