require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'net/http'
require 'uri'
require 'rest_client'

class Result
  attr_accessor :bing, :wikipedia, :altered_query, :trend
end

class TwitterCallController < ApplicationController
  def index

    # Get the available locations from Twitter
    locations = {}
    avail_xml = Nokogiri::XML(open("http://api.twitter.com/1/trends/available.xml"))
    avail_xml.xpath("//location").each do |l|
      woeid = l.xpath("woeid").first.content
      name = l.xpath("name").first.content
      locations[woeid] = name
    end
    @locations = locations

    # Get the trending topics and put them into an array
    trends = []
    twitter_xml = Nokogiri::XML(open("http://api.twitter.com/1/trends/1.xml"))
    twitter_xml.xpath("//trend").each do |t|
      trends << (t.content[0] == "#" ? t.content[1..-1] : t.content) # Remove hash
    end
    @trends = trends
    puts @trends
    @results = []

    @trends.each do |trend|
      puts trend
      result = Result.new
      result.trend = trend

      # Search Bing and get back
      # - Description of top result
      # - Altered search query if there exists one
      search_query = trend
      #search_xml = Nokogiri::XML(open("http://api.search.live.net/xml.aspx?Appid=D922B026428E58D0B1B38C3CB94E227BF6B113BB&query=#{search_query}&sources=web"))
      search_xml = Nokogiri::XML(open("http://api.search.live.net/xml.aspx?Appid=D922B026428E58D0B1B38C3CB94E227BF6B113BB&query=#{CGI.escape(search_query)}&sources=web"))
      puts search_xml
      search_ns = {"xmlns:sr" => "http://schemas.microsoft.com/LiveSearch/2008/04/XML/element", "xmlns:web" => "http://schemas.microsoft.com/LiveSearch/2008/04/XML/web"}
      search_top_path = search_xml.xpath("/sr:SearchResponse/web:Web/web:Results/web:WebResult/web:Description",search_ns).first
      if not search_top_path
        next
      end
      search_top = search_top_path.content
      search_altered_xpath = search_xml.xpath("/sr:SearchResponse/sr:Query/sr:AlteredQuery",search_ns)
      search_altered = search_altered_xpath.first ? search_altered_xpath.first.content : ""
      result.bing = search_top 
      result.altered_query = search_altered

      # Search Wikipedia and get back top search result if any
      db_query = search_altered == "" ? search_query : search_altered
      puts db_query
      db_xml = Nokogiri::XML(open("http://en.wikipedia.org/w/api.php?action=opensearch&search=#{CGI.escape(db_query)}&limit=2&namespace=0&format=xml"))
      db_ns = {"xmlns:ss" => "http://opensearch.org/searchsuggest2"}
      db_abstract_xpath = db_xml.xpath("/ss:SearchSuggestion/ss:Section/ss:Item/ss:Description",db_ns)
      db_abstract = db_abstract_xpath.first ? db_abstract_xpath.first.content : ""
      result.wikipedia = db_abstract 

      @results << result

    end

    # Output XML
    @builder = Nokogiri::XML::Builder.new do |xml|
        xml.entry(:xmlns => "http://www.w3.org/2005/Atom") {
          xml.title "Location and time of query (TODO)"
          xml.content(:type => "xhtml") {
            xml.parent.content = "Hello"
          }

          xml.trends(:xmlns => "http://my.superdupertren.ds", :location => "test") {           
            trends.each_with_index do |t,i|
              xml.trend(:xmlns => "http://api.twitter.com", :topic => t) {
                xml.top_result(:xmlns => "http://www.bing.com") {
                  xml.parent.content = @results[i].bing
                }
                xml.abstract(:xmlns => "http://www.wikipedia.org") {
                  xml.parent.content = @results[i].wikipedia
                }
              }
            end
          }
        }
    end
    @builder.to_xml

    # Old Stuff
    # # Get the abstract for Blankety Blank from DBPedia
    # db_xml = Nokogiri::XML(open("http://dbpedia.org/data/Blankety_Blank.rdf"))
    # # Collect namespaces (spend more time by uncommenting)
    # #db_ns = db_xml.collect_namespaces()
    # db_ns = {"xmlns:rdf"=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "xmlns:rdfs"=>"http://www.w3.org/2000/01/rdf-schema#", "xmlns:dcterms"=>"http://purl.org/dc/terms/", "xmlns:dbpprop"=>"http://dbpedia.org/property/", "xmlns:dbpedia-owl"=>"http://dbpedia.org/ontology/", "xmlns:foaf"=>"http://xmlns.com/foaf/0.1/", "xmlns:n0pred"=>"http://dbpedia.org/ontology/Work/", "xmlns:owl"=>"http://www.w3.org/2002/07/owl#"}
    # @abstract = db_xml.xpath("//dbpedia-owl:abstract[@xml:lang='en']",db_ns).first.content

  end
  
  # Get latest trends
  def latest
    location_id = params[:id]
    puts "My Location ID is %s" % [location_id]
    
    trends_xml = index
    url= "http://localhost:8080"
    r = RestClient::Resource.new url
    res = r["exist/atom/edit/4302Collection/root-trends"].post trends_xml, :content_type => "application/atom+xml"
    render :xml => res
  end
  
  # Get all trends
  def all
    location_id = params[:id]
    url= "http://localhost:8080"
    r = RestClient::Resource.new url
    res = r["exist/atom/content/4302Collection/root-trends"].get
    render :xml => res
  end
  
  def update
    # Given the ID and Trend_Name and Comment Text, update
  end

  def create
    xml = <<EOF
<?xml version="1.0" ?>
<entry xmlns="http://www.w3.org/2005/Atom">
<title>My First Entry</title>
<content type='xhtml'>
<div xmlns='http://www.w3.org/1999/xhtml'>
<p>Isn't life grand!?!</p>
</div>
</content>
</entry>
EOF

    url= "http://localhost:8080"
    r = RestClient::Resource.new url
    res = r["exist/atom/edit/4302Collection/root-trends"].post entry_xml, :content_type => "application/atom+xml"
    puts res
    render :xml => res
  end
  
  #this function should only be called once for setting up collections and feeds
  def setup_atom
    create_collection()
    create_feed()
  end

  # If you get a 401 Unauthorized Error it means the collection already exists!
  def create_collection
    collection_setup = '<?xml version="1.0" ?><feed xmlns="http://www.w3.org/2005/Atom"><title>Trend Explainer</title></feed>'
    url= "http://localhost:8080/exist/atom/edit/4302Collection"
    r = RestClient::Resource.new url
    res = r.post collection_setup, :content_type => "application/atom+xml"
    puts res
  end

  def create_feed
    feed_setup = '<?xml version="1.0" ?><feed xmlns="http://www.w3.org/2005/Atom"><title>Root trends</title><author><name>Justin-Paul-Steven</name></author></feed>'
    url= "http://localhost:8080"
    r = RestClient::Resource.new url
    res = r["exist/atom/edit/4302Collection/root-trends"].post feed_setup, :content_type => "application/atom+xml"
    puts res
  end
  
  def update_feed
    feed_setup = '<?xml version="1.0" ?><feed xmlns="http://www.w3.org/2005/Atom"><title>rrrrrrrrrrr trends</title><author><name>Justin-Paul-Steven</name></author></feed>'
    url= "http://localhost:8080"
    r = RestClient::Resource.new url
    res = r["exist/atom/edit/4302Collection/fffffffffffff"].put feed_setup, :content_type => "application/atom+xml"
    puts res
    render :text => res
  end
  
  def test
    url_str = "http://localhost:8080/exist/atom/introspect/4302Collection"
    res = RestClient.get url_str
    render :xml => res
    #return res.body
  end

end
