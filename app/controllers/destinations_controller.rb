require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'digest'

class DestinationsController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    @city = params[:search_term]

    # API later takes time in seconds while user inputs in hours, so converting below
    @max_travel_time = params[:max_travel_hours].to_i * 3600

    # free plan limits travel time to one hour, so resetting to max this value below for now...
    @max_travel_time = 3600 if @max_travel_time > 3600
    # We currently destroy all destinations to make sure that we only show the ones close and not those created in previous requests
    # we will probably want to change this going forward so that we can add reviews etc + potentially reduce loading times
    # Destination.destroy_all

    # creating the geocodes on the searched for starting city below, these are passed into the API request URL to get the list of potential destinations
    coordinates = Geocoder.search(@city)
    lat = coordinates.first.coordinates[0]
    long = coordinates.first.coordinates[1]

    # setting the limit of cities we want to pull data for (can go up to 100 but increases load time)
    cities_limit = 50
    population_limit = 50000

    # running API to get list of cities within 500k radius of start location, with over 100k inhabitants.
    # API returns list of closest cities fulfilling these criteria, with the length of the list specified above
    url = URI("https://wft-geo-db.p.rapidapi.com/v1/geo/locations/#{lat.positive? ? "+" : ""}#{lat}#{long.positive? ? "+" : ""}#{long}/nearbyCities?radius=500&limit=#{cities_limit}&minPopulation=#{population_limit}&distanceUnit=KM&languageCode=en&types=CITY")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["X-RapidAPI-Host"] = 'wft-geo-db.p.rapidapi.com'
    request["X-RapidAPI-Key"] = 'c9d28d232dmsh2d27d7b3c93db5ep18ab12jsn6dc0f6eb8456'

    # the api request is submitted and the received answer is transformed into destinations, as long as the destination does not exist already
    # and as long as the destination is at least 25k from the start location (we do not want our list filled with sub-urbs to the starting location)
    # have temporarily limited destination difference to only 10k so that we can test if second API doing what we want
    response = http.request(request)


    # new approach
    @destinations = []
    JSON.parse(response.read_body)["data"].each do |dest_response|
      next if dest_response["distance"] < 10
      @destinations << [name: dest_response["name"], wikidata_id: dest_response["wikiDataId"], latitude: dest_response["latitude"], longitude: dest_response["longitude"], description: "Nice city"]
    end

    # data is passed to the view but also defined for API request creation loop below
    # @destinations = Destination.all

    # at this point we have all the close cities saved in the Destination model, with data incl
    # city name, wikidata_id and coordinates + a fake description

    # BELOW WE ARE NOW MOVING INTO THE TRAVEL TIME API CALCULATING THE TRAVEL TIME FROM OUR START LOCATION AND POTENTIAL DESTINATIONS

    # The below part body params is the structure of the API request we need to submit
    # we set departure-location_id to "city" which is the result of the search above. This is not updated further down
    # the other parts of the body_params are filled in with the destination data created above in the next step
    # travel time set to noon in the below request so if we add public transport it is not too skewed by time of request (e.g. if someone uses it at midnight)

    body_params = {
      "locations": [{
        "id": @city,
        "coords": {
          "lat": lat,
          "lng": long
        }
      }],
      "departure_searches": [
        {
          "id": "One-to-many Matrix",
          "departure_location_id": @city,
          "arrival_location_ids": [],
          "transportation": {
            "type": "driving"
          },
          "departure_time": Time.now.noon,
          "travel_time": @max_travel_time,
          "properties": [
          "travel_time",
          "distance"
          ]
        }
      ]
    }

    # here we add each destination created above as a location to the api request we will submit longer
    # as you can see we are adding them into the locations at the beginning of the body_params (full coordiantes data)
    # and their IDs at the location id at the end (API pulls coordinates from initial entry)
    # the departure location is not changed here and hence still set to city as above
    @destinations.each do |destination|
      body_params[:locations] << {
        "id": destination[0][:wikidata_id],
        "coords": {
          "lat": destination[0][:latitude],
          "lng": destination[0][:longitude]
        }
      }
      body_params[:departure_searches][0][:arrival_location_ids] << destination[0][:wikidata_id]
    end

    # we set up the API (which URL to submit request to etc)

    url_2 = URI("https://api.traveltimeapp.com/v4/time-filter")
    http_2 = Net::HTTP.new(url_2.host, url_2.port)
    http_2.use_ssl = true
    http_2.verify_mode = OpenSSL::SSL::VERIFY_NONE

    # we submit the request as JSON and received the returning data, which we need to parse from JSON
    request_2 = Net::HTTP.post(url_2, body_params.to_json, {"Content-Type": 'application/json', "X-Application-Id": '2d711dce', "X-Api-Key": '8bd81cf8e989810db68666a3e90057db'})

    # we parse the returned data into JSON so we can work with it
    data_2 = JSON.parse(request_2.read_body)

    @near_destinations = []

    # each travel_hash has format: {"id"=>"Q3974", "properties"=>[{"travel_time"=>3365, "distance"=>74498}]}
    data_2["results"][0]["locations"].each do |travel_hash|
      destination_array = @destinations.find { |i| i[0][:wikidata_id] == travel_hash["id"] }
      destination_hash = destination_array[0]
      destination_hash[:travel_time] = travel_hash["properties"][0]["travel_time"]
      @near_destinations << destination_hash
    end

    # ADDING FINAL API TO PULL DESTINATION DESCRIPTION AND IMAGE URL

    wiki_ids = []
    @near_destinations.each do |near_dest|
      wiki_ids << near_dest[:wikidata_id]
    end

    wiki_id_input_for_API = wiki_ids.join("|")

    # adding in the description and image for each location

    # url = "https://www.wikidata.org/w/api.php?action=wbgetclaims&property=P18&entity=#{wikidata_id}&format=json"
    url = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wiki_id_input_for_API}&format=json&languages=en&props=descriptions|claims"
    uri = URI(url)
    # response = Net::HTTP.get(uri)
    @near_destinations.each do |near_dest|
      picture_name = JSON.parse(Net::HTTP.get(uri))["entities"][near_dest[:wikidata_id]]["claims"]["P18"][0]["mainsnak"]["datavalue"]["value"]
      picture_name_2 = picture_name.gsub(/\s/,'_')
      picture_md5 = Digest::MD5.hexdigest picture_name_2
      a = picture_md5[0]
      b = picture_md5[1]
      near_dest[:picture_url] = "https://upload.wikimedia.org/wikipedia/commons/#{a}/#{a}#{b}/#{picture_name_2}"
      near_dest[:description] = JSON.parse(Net::HTTP.get(uri))["entities"][near_dest[:wikidata_id]]["descriptions"]["en"]["value"].upcase_first
    end

    # @near_destinations.each do |city|
    #   next if Destination.exists?(:wikidata_id => city[:wikidata_id])
    #   new_city = Destination.new(name: city[:name], wikidata_id: city[:wikidata_id], latitude: city[:latitude], longitude: city[:longitude], description: city[:description])
    #   new_city.save
    # end

  end
end
