require 'open-uri'
require 'nokogiri'

class TwitterCallController < ApplicationController
  def index
    
    # Get the trending topics and put them into an array
    trends = []
    twitter_xml = Nokogiri::XML(open("http://api.twitter.com/1/trends/1.xml"))
    twitter_xml.xpath("//trend").each do |t|
      trends << (t.content[0] == "#" ? t.content[1..-1] : t.content) # Remove hash
    end
    
    @tweb = trends
  end

end
