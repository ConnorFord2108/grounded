class CreateTravelPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :travel_plans do |t|
      t.date :start_date
      t.date :end_date
      t.text :comment
      t.references :user, null: false, foreign_key: true
      t.references :destination, null: false, foreign_key: true

      t.timestamps
    end
  end
end
