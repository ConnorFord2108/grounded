class CreateDestinations < ActiveRecord::Migration[6.1]
  def change
    create_table :destinations do |t|
      t.text :description
      t.string :address

      t.timestamps
    end
  end
end
