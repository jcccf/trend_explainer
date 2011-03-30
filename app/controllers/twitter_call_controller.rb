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
        xml.entry {
          xml.parent.default_namespace = "http://www.w3.org/2005/Atom"
          xml.title "Radio Head"
          xml.content("type"=>"xhtml") {
            xml.parent.content = "Hello"
          }
        }
    end
    #puts @builder.to_xml

    # Old Stuff
    # # Get the abstract for Blankety Blank from DBPedia
    # db_xml = Nokogiri::XML(open("http://dbpedia.org/data/Blankety_Blank.rdf"))
    # # Collect namespaces (spend more time by uncommenting)
    # #db_ns = db_xml.collect_namespaces()
    # db_ns = {"xmlns:rdf"=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "xmlns:rdfs"=>"http://www.w3.org/2000/01/rdf-schema#", "xmlns:dcterms"=>"http://purl.org/dc/terms/", "xmlns:dbpprop"=>"http://dbpedia.org/property/", "xmlns:dbpedia-owl"=>"http://dbpedia.org/ontology/", "xmlns:foaf"=>"http://xmlns.com/foaf/0.1/", "xmlns:n0pred"=>"http://dbpedia.org/ontology/Work/", "xmlns:owl"=>"http://www.w3.org/2002/07/owl#"}
    # @abstract = db_xml.xpath("//dbpedia-owl:abstract[@xml:lang='en']",db_ns).first.content

  end

  def get
    url_str = "http://localhost:8080/exist/atom/introspect/4302Collection/root-trends"
    res = RestClient.get url_str
    render :xml => res
    #return res.body
  end

  def get_all
    xml_res = get()
    return xml_res
  end

  def get_latest
    xml_res = get()
    #TODO: need to get the latest
  end

  def post_entry(entry_xml)
    url= "http://localhost:8080"
    r = RestClient::Resource.new url
    r["exist/atom/edit/4302Collection/root-trends"].post entry_xml, :content_type => "application/atom+xml"
    puts r.to_s
    return r.to_s
  end

  def post
    xml = '<?xml version="1.0" ?><entry xmlns="http://www.w3.org/2005/Atom"><title>Hello Horse</title><content><p>hello horse is alpaca</p></content></entry>'
    res = post_entry(xml)
    render :xml => res
  end

  def put
    feed_setup = '<?xml version="1.0" ?><feed xmlns="http://www.w3.org/2005/Atom"><title>rrrrrrrrrrr trends</title><author><name>Justin-Paul-Steven</name></author></feed>'
    url= "http://localhost:8080"
    r = RestClient::Resource.new url
    r["exist/atom/edit/4302Collection/fffffffffffff"].put feed_setup, :content_type => "application/atom+xml"
    puts r.to_s

    render :text => r.to_s
  end

  def post_collection
    collection_setup = '<?xml version="1.0" ?><feed xmlns="http://www.w3.org/2005/Atom"><title>Trend Explainer</title></feed>'
    url= "http://localhost:8080/exist/atom/edit/4302Collection"
    r = RestClient::Resource.new url
    r.post collection_setup, :content_type => "application/atom+xml"
  end

  def post_feed
    feed_setup = '<?xml version="1.0" ?><feed xmlns="http://www.w3.org/2005/Atom"><title>Root trends</title><author><name>Justin-Paul-Steven</name></author></feed>'
    url= "http://localhost:8080"
    r = RestClient::Resource.new url
    r["exist/atom/edit/4302Collection/root-trends"].post feed_setup, :content_type => "application/atom+xml"
    puts r.to_s
  end

  #this function should only be called once for setting up collections and feeds
  def post_collection_feed
    post_collection()
    post_feed()
  end




end
