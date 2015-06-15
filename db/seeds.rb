# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

generated_password = Devise.friendly_token.first(12)
Admin.create(email: 'initialadmin@hms.harvard.edu', password: generated_password)
puts "Admin password: #{generated_password}"