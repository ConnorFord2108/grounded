# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

TravelPlan.create(start_date: Date.today, end_date: Date.today, comment: "here we go", user_id: 1, destination_id: 1)

User.create(last_name: "Ford", first_name: "Connor", password: "123456", email: "ford@email.com")
