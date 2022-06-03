class AddPictureUrlToDestinations < ActiveRecord::Migration[6.1]
  def change
    add_column :destinations, :picture_url, :string
  end
end
