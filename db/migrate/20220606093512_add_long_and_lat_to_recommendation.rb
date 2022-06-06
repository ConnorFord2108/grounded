class AddLongAndLatToRecommendation < ActiveRecord::Migration[6.1]
  def change
    add_column :recommendations, :longitude, :float
    add_column :recommendations, :latitude, :float
  end
end
