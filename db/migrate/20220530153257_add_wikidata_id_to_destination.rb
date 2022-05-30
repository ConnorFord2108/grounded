class AddWikidataIdToDestination < ActiveRecord::Migration[6.1]
  def change
    add_column :destinations, :wikidata_id, :string
  end
end
