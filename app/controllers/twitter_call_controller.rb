require 'open-uri'
require 'nokogiri'

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
    
    @results = []
    
    @trends.each do |trend|
      
      # Search Bing and get back
      # - Description of top result
      # - Altered search query if there exists one
      search_query = trend
      search_xml = Nokogiri::XML(open("http://api.search.live.net/xml.aspx?Appid=D922B026428E58D0B1B38C3CB94E227BF6B113BB&query=#{CGI.escape(search_query)}&sources=web"))
      search_ns = {"xmlns:sr" => "http://schemas.microsoft.com/LiveSearch/2008/04/XML/element", "xmlns:web" => "http://schemas.microsoft.com/LiveSearch/2008/04/XML/web"}
      search_top = search_xml.xpath("/sr:SearchResponse/web:Web/web:Results/web:WebResult/web:Description",search_ns).first.content
      search_altered_xpath = search_xml.xpath("/sr:SearchResponse/sr:Query/sr:AlteredQuery",search_ns)
      search_altered = search_altered_xpath.first ? search_altered_xpath.first.content : ""
      @results << "Bing: " + search_top 
      @results << "Altered Query: " + search_altered
      
      # Search Wikipedia and get back top search result if any
      db_query = search_altered == "" ? search_query : search_altered
      db_xml = Nokogiri::XML(open("http://en.wikipedia.org/w/api.php?action=opensearch&search=#{CGI.escape(db_query)}&limit=2&namespace=0&format=xml"))
      db_ns = {"xmlns:ss" => "http://opensearch.org/searchsuggest2"}
      db_abstract_xpath = db_xml.xpath("/ss:SearchSuggestion/ss:Section/ss:Item/ss:Description",db_ns)
      db_abstract = db_abstract_xpath.first ? db_abstract_xpath.first.content : ""
      @results << "Wikipedia: " + db_abstract 

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

end
