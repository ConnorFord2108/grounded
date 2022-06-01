class CreateRecommendations < ActiveRecord::Migration[6.1]
  def change
    create_table :recommendations do |t|
      t.references :destination, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.integer :num_reviews
      t.float :rating

      t.timestamps
    end
  end
end
