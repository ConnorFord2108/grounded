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

    # creating the geocodes on the searched for starting city below, these are passed into the API request URL to get the list of potential destinations
    coordinates = Geocoder.search(@city)
    lat = coordinates.first.coordinates[0]
    long = coordinates.first.coordinates[1]

    # setting the limit of cities we want to pull data for (can go up to 100 but increases load time)
    cities_limit = 50
    population_limit = 50000

    # running API to get list of cities (# specified above) within 500k radius of start location, with over X inhabitants (specified above).
    # API returns list of closest cities fulfilling these criteria, with the length of the list specified above
    url = URI("https://wft-geo-db.p.rapidapi.com/v1/geo/locations/#{lat.positive? ? "+" : ""}#{lat}#{long.positive? ? "+" : ""}#{long}/nearbyCities?radius=500&limit=#{cities_limit}&minPopulation=#{population_limit}&distanceUnit=KM&languageCode=en&types=CITY")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["X-RapidAPI-Host"] = 'wft-geo-db.p.rapidapi.com'
    request["X-RapidAPI-Key"] = 'c9d28d232dmsh2d27d7b3c93db5ep18ab12jsn6dc0f6eb8456'

    # we apply a minimum distance from the start location in km (we do not want our list filled with sub-urbs to the starting location)
    minimum_distance_from_start = 10

    # the api request is submitted and the received answer is transformed into a destinations hash storing the newly pulled data
    # it is not saved in the database here as only few cities will make it through and saving all takes a lot of unnecessary time
    # with premium account for travel time API 25k distance limit is probably better idea (with non-premium too few make it through)
    response = http.request(request)
    @destinations = []
    JSON.parse(response.read_body)["data"].each do |dest_response|
      next if dest_response["distance"] < minimum_distance_from_start
      @destinations << [name: dest_response["name"], wikidata_id: dest_response["wikiDataId"], latitude: dest_response["latitude"], longitude: dest_response["longitude"], description: "Nice city"]
    end

    # BELOW WE ARE NOW MOVING INTO THE TRAVEL TIME API CALCULATING THE TRAVEL TIME FROM OUR START LOCATION TO POTENTIAL DESTINATIONS
    # The below part body params is the structure of the API request we need to submit
    # we set departure-location_id to "city" which is the result of the search on the home page stored above. This is not updated further down
    # the other parts of the body_params are filled in with the destination data created above
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
    # here we add each destination created above to the api request (as a location)
    # as you can see we are adding them into the locations at the beginning of the body_params (full coordiantes data)
    # and their IDs at the location id at the end (API pulls coordinates from initial locations entry)
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

    # empty near_destinations variable created to store those destinations which actually are within the travel time limit
    @near_destinations = []

    # we itterate over the results part of API response regarding travel time which only includes those destinations which are reachable in the travel  time
    # each travel_hash has format: {"id"=>"Q3974", "properties"=>[{"travel_time"=>3365, "distance"=>74498}]}
    data_2["results"][0]["locations"].each do |travel_hash|
      # for these we find the responding destination data created from API 1 above
      destination_array = @destinations.find { |i| i[0][:wikidata_id] == travel_hash["id"] }
      # as the destination hash is stored in an arry we must take the first element from it
      destination_hash = destination_array[0]
      # we then add a travel time key to the destination hash using the results from the travel time API
      destination_hash[:travel_time] = travel_hash["properties"][0]["travel_time"]
      # finally we add the destinations which are within the travel time limit into the new array of relevant destinations only
      @near_destinations << destination_hash
    end

    # ADDING FINAL API TO PULL DESTINATION DESCRIPTION AND IMAGE URL
    # A wiki IDs variable containing all wiki IDs of the relevant destinations is created
    # as we need to pass these into the API to get description and image for each destination
    wiki_ids = []
    @near_destinations.each do |near_dest|
      wiki_ids << near_dest[:wikidata_id]
    end

    # the array of wiki IDs is converted into a string of the format ID1|ID2|ID3 to match API requirements
    wiki_id_input_for_API = wiki_ids.join("|")

    # the base url for the API is adjusted to pull the data for our specific destinations
    url = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wiki_id_input_for_API}&format=json&languages=en&props=descriptions%7Cclaims"

    # the url is converted into a URI which the nethttp gem can work with
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)["entities"]

    # adding default image array for those cities where WikiData does not have default, array so one can be sampled and if several lack pic not all look same
    default_image_array = ["https://images.unsplash.com/photo-1555658636-6e4a36218be7?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1770&q=80",
      "https://images.unsplash.com/photo-1498654896293-37aacf113fd9?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1770&q=80",
      "https://images.unsplash.com/photo-1544161442-e3db36c4f67c?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1978&q=80",
      "https://images.unsplash.com/photo-1535958636474-b021ee887b13?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1770&q=80"
    ]

    # for each near destination we parse the response data
    @near_destinations.each do |near_dest|
      if data[near_dest[:wikidata_id]]["claims"]["P18"].nil?
        near_dest[:picture_url] = default_image_array.sample
      else
        picture_name = data[near_dest[:wikidata_id]]["claims"]["P18"][0]["mainsnak"]["datavalue"]["value"]
        picture_name_2 = picture_name.gsub(/\s/,'_')
        picture_md5 = Digest::MD5.hexdigest picture_name_2
        a = picture_md5[0]
        b = picture_md5[1]
        near_dest[:picture_url] = "https://upload.wikimedia.org/wikipedia/commons/#{a}/#{a}#{b}/#{picture_name_2}"
      end
      if data[near_dest[:wikidata_id]]["descriptions"]["en"].nil?
        near_dest[:description] = "Beautiful city close to #{@city}"
      else
        near_dest[:description] = data[near_dest[:wikidata_id]]["descriptions"]["en"]["value"].upcase_first
      end
    end
    # using asyncron job to perform creation to not slow down loading
    CreateDestinationsJob.perform_later(@near_destinations)
  end

  def show
    @destination = Destination.last
    # @destination.recommendations&.destroy_all
    longitude = @destination.longitude
    latitude = @destination.latitude

    if @destination.recommendations.empty?
      url = URI("https://travel-advisor.p.rapidapi.com/attractions/list-by-latlng?longitude=#{longitude}&latitude=#{latitude}&lunit=km&currency=USD&lang=en_US")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      request["X-RapidAPI-Host"] = 'travel-advisor.p.rapidapi.com'
      request["X-RapidAPI-Key"] = '05e37c7835mshe38bce0736bf094p1546dejsnc66cc7f9539c'

      response = http.request(request)
      json_file = JSON.parse(response.read_body)['data']

      json_file.each do |attraction|
        # recommendations should contain name, rating, num_reviews, photo, description
        if attraction.key?('rating') && attraction.key?('photo') && attraction.key?('name') && attraction.key?('description') && attraction.key?('num_reviews')
          if attraction['rating'].to_f >= 4 && !(attraction['description'] == "")
            recommendation = Recommendation.new
            recommendation.destination_id = @destination.id
            recommendation.name = attraction['name']
            recommendation.rating = attraction['rating']
            recommendation.num_reviews = attraction['num_reviews']
            recommendation.photo_url = attraction['photo']['images']['small']['url']
            recommendation.description = attraction['description']
            recommendation.save
          end
        end

      end

      end
      @recommendations = @destination.recommendations
    end
end
