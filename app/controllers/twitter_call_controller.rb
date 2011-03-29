require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'net/http'
require 'uri'

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
          xml.title = "Location and time of query (TODO)"
          xml.content(:type => "xhtml") {
            xml.parent.content = "Hello"
          }

          xml.trends(:xmlns => "http://api.twitter.com", :location => "test") {           
            trends.each_with_index do |t,i|
              xml.trend(:topic => t) {
                xml.top_result(:xmlns => "http://www.bing.com") {
                  xml.parent.content = result.bing[i]
                }
                xml.abstract(:xmlns => "http://www.wikipedia.org") {
                  xml.parent.content = result.wikipedia[i]
                }
              }
            end
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
    url_str = "http://localhost:8080/exist/atom/introspect/4302Collection"
    url = URI.parse(url_str)
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    puts res.body
    render :xml => res.body

  end

  def post
    url_str = "http://localhost:8080/exist/atom/edit/4302Collection"
    url = URI.parse(url_str)
    request = Net::HTTP::Post.new(url.path)
    xml_str = '<?xml version="1.0" ?><feed xmlns="http://www.w3.org/2005/Atom"><title>trend_explaner</title></feed>'
    puts "url string initiated"
    request.body = xml_str
    res = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    puts res.body
    render :text => "OK"
  end

end
