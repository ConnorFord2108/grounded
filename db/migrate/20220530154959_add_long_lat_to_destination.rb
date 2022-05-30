class AddLongLatToDestination < ActiveRecord::Migration[6.1]
  def change
    add_column :destinations, :longitude, :float
    add_column :destinations, :latitude, :float
  end
end
