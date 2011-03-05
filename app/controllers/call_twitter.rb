require "open-uri"

tweb = open("http://api.twitter.com/1/trends/available.xml").read

#now parse it!
