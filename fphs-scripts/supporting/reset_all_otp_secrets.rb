uc = ENV['FPHS_RESET_USERS']
if uc == 'users'
  klass = User
elsif uc == 'admins'
  klass = Admin
else
  puts "Unknown class of users. Use either users or admins as the first argument."
  exit 1
end

n = 0

klass.active.each do |u|
  u.reset_two_factor_auth
  u.save!
  n += 1
end

puts "Updated #{n} #{uc}"
