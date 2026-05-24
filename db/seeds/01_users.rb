User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password"
  u.role = :admin
end

User.find_or_create_by!(email: "user@example.com") do |u|
  u.password = "password"
  u.role = :general
end

User.find_or_create_by!(email: "ai@anisonar.internal") do |u|
  u.password = SecureRandom.hex(24)
  u.role = :ai
end
