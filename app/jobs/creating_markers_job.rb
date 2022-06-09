class CreatingMarkersJob < ApplicationJob
  queue_as :default

  def perform(near_destinations, lat, lng)
    @start_marker = {
      lat: lat,
      lng: lng,
      image_url: helpers.asset_url("Vector (8).svg")
    }

    @markers = near_destinations.map do |city| {
      lat: city[:latitude],
      lng: city[:longitude],
      info_window: render_to_string(partial: "info_window", locals: { destination: city
      }),
      image_url: helpers.asset_url("Vector (9).svg")
      }
    end
    @markers << @start_marker
  end
end
