class DestinationsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'openssl'
  require "Json"



  def index
    url = URI("https://wft-geo-db.p.rapidapi.com/v1/geo/locations/+48.137154+11.576124/nearbyCities?radius=100&minPopulation=1000&distanceUnit=KM")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    response = http.request(request)
    JSON.parse(response.read_body)["data"].each do |city|
      Destination.new(name: city["name"], wikidata_id: city["wikiDataId"], latitude: city["latitude"], longitude: city["longitude"], description: "Nice city")
      Destination.save
    end
    @destination = Destination.all
  end
end
