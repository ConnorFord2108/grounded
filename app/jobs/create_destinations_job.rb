class CreateDestinationsJob < ApplicationJob
  queue_as :default

  def perform(near_destinations)
    near_destinations.each do |city|
      next if @destination_instances.exists?(:wikidata_id => city[:wikidata_id])
      new_city = Destination.new(name: city[:name], wikidata_id: city[:wikidata_id], latitude: city[:latitude], longitude: city[:longitude], description: city[:description], picture_url: city[:picture_url])
      new_city.save
    end
  end
end
