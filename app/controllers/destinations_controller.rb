require 'uri'
require 'net/http'
require 'openssl'

class DestinationsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # http://localhost:3000/destinations?city=paris&radius=100

    city = params[:city]
    radius = params[:radius]
    coordinates = Geocoder.search(city)
    lat = coordinates.first.coordinates[0]
    long = coordinates.first.coordinates[1]
    url = URI("https://wft-geo-db.p.rapidapi.com/v1/geo/locations/#{lat}+#{long}/nearbyCities?radius=#{radius}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    request["X-RapidAPI-Host"] = 'wft-geo-db.p.rapidapi.com'
    request["X-RapidAPI-Key"] = '8bb2f59f6fmsh6d281e5a931b2c5p1ff197jsn983bf5c90d99'
    response = http.request(request)
    @destinations = JSON.parse(response.read_body)["data"]

    body_params = {
      "locations": [{
        "id": city,
        "coords": {
          "lat": lat,
          "lng": long
        }
      }],
      "departure_searches": [
        {
          "id": "One-to-many Matrix",
          "departure_location_id": city,
          "arrival_location_ids": [],
          "transportation": {
            "type": "driving"
          },
          "departure_time": Time.now,
          "travel_time": 3600,
          "properties": [
          "travel_time",
          "distance"
          ]
        }
      ]
    }

    @destinations.each do |destination|
      body_params[:locations] << {
        "id": destination["name"],
        "coords": {
          "lat": destination["latitude"],
          "lng": destination["longitude"]
        }
      }
      body_params[:departure_searches][0][:arrival_location_ids] << destination["name"]
    end

    url_2 = URI("https://api.traveltimeapp.com/v4/time-filter")
    http_2 = Net::HTTP.new(url_2.host, url_2.port)
    http_2.use_ssl = true
    http_2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request_2 = Net::HTTP.post(url_2, body_params.to_json, {"Content-Type": 'application/json', "X-Application-Id": '2d711dce', "X-Api-Key": '8bd81cf8e989810db68666a3e90057db'})
    raise
  end

end
