class RenameAddressToNameForDestinations < ActiveRecord::Migration[6.1]
  def change
    rename_column :destinations, :address, :name
  end
end
