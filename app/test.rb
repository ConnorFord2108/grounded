require 'net/http'
require 'json'

wikidata_id = "Q544939"

url = "https://www.wikidata.org/w/api.php?action=wbgetclaims&property=P18&entity=#{wikidata_id}&format=json"
uri = URI(url)
response = Net::HTTP.get(uri)

picture_name = JSON.parse(response)["claims"]["P18"][0]["mainsnak"]["datavalue"]["value"]
