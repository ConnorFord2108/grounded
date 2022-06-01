require 'net/http'
require 'json'
require 'digest'

wikidata_id = "Q544939"

# we can do several entities at once with |

# url = "https://www.wikidata.org/w/api.php?action=wbgetclaims&property=P18&entity=#{wikidata_id}&format=json"
url = "https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wikidata_id}&format=json&languages=en&props=descriptions|claims"
uri = URI(url)
# response = Net::HTTP.get(uri)

picture_name = JSON.parse(Net::HTTP.get(uri))["entities"][wikidata_id]["claims"]["P18"][0]["mainsnak"]["datavalue"]["value"]
picture_name_2 = picture_name.gsub(/\s/,'_')
picture_md5 = Digest::MD5.hexdigest picture_name_2
a = picture_md5[0]
b = picture_md5[1]
picture_url = "https://upload.wikimedia.org/wikipedia/commons/#{a}/#{a}#{b}/#{picture_name_2}"

description = JSON.parse(Net::HTTP.get(uri))["entities"][wikidata_id]["descriptions"]["en"]["value"].upcase_first
