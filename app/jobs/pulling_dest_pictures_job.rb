class PullingDestPicturesJob < ApplicationJob
  queue_as :default

  def perform(near_destinations)
    # ADDING FINAL API TO PULL DESTINATION DESCRIPTION AND IMAGE URL
    # A wiki IDs variable containing all wiki IDs of the relevant destinations is created
    # as we need to pass these into the API to get description and image for each destination
    wiki_ids = []
    near_destinations.each do |near_dest|
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

    return data
  end
end
