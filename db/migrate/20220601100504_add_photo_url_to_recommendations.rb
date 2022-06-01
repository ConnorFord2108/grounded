class AddPhotoUrlToRecommendations < ActiveRecord::Migration[6.1]
  def change
    add_column :recommendations, :photo_url, :string
  end
end
