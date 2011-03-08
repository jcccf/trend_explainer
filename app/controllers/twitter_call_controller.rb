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
    
    # Get the abstract for Blankety Blank
    db_xml = Nokogiri::XML(open("http://dbpedia.org/data/Blankety_Blank.rdf"))
    # Collect namespaces (spend more time by uncommenting)
    #db_ns = db_xml.collect_namespaces()
    db_ns = {"xmlns:rdf"=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "xmlns:rdfs"=>"http://www.w3.org/2000/01/rdf-schema#", "xmlns:dcterms"=>"http://purl.org/dc/terms/", "xmlns:dbpprop"=>"http://dbpedia.org/property/", "xmlns:dbpedia-owl"=>"http://dbpedia.org/ontology/", "xmlns:foaf"=>"http://xmlns.com/foaf/0.1/", "xmlns:n0pred"=>"http://dbpedia.org/ontology/Work/", "xmlns:owl"=>"http://www.w3.org/2002/07/owl#"}
    @abstract = db_xml.xpath("//dbpedia-owl:abstract[@xml:lang='en']",db_ns).first.content
    
  end

end
