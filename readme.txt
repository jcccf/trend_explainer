Trend Explainer readme.txt

a. NAME and NETIDs
==================
Justin Cheng (jc882)
Heran Yang (hy279)
Stephen Moseson (scm42)

b. Data Sources
===============
* Twitter (Data access type: API)
  - Trends (http://apiwiki.twitter.com/w/page/22554753/Twitter-REST-API-Method:-trends-location)
  - Locations (http://apiwiki.twitter.com/w/page/22554752/Twitter-REST-API-Method:-trends-available)

* Bing (Data access type: API)
  - Web search (http://www.bing.com/developers/s/API%20Basics.pdf)

* Wikipedia (Data access type: API)
  - Open search (http://www.mediawiki.org/wiki/API:Opensearch)

- Notes: all info recieved from the above APIs is in XML format. 

c. Mashup and Atom feeds composition
======
From Twitter, we take the top trending topics for a user defined location at a specific time, and then search Bing and Wikipedia to explain what these top trending topics mean and why they are important at the mean time. For example, user selects "San Francisco" as the location option. The top trends from Twitter San Francisco will be searched on Bing and Wiki one by one. After we combine the two data sources, we will create a new entry containing all trending topics at this specific moment. Our atom composition's tree structure is: a collection named 4302Collections => feeds for different locations, e.g. San Francisco => entries for top trends at specific time, e.g. 9:15pm, Apr 2nd, 2011. Therefore two user searches for a same location will be two different entries under the same location feed. 
