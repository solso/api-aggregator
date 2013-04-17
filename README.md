
## API AGGREGATOR

API Aggregator is a system that combines lua and nginx to have a sandbox environment where you can safely run user generated scripts that do API aggregation. 

**Why API aggregation?**

REST API's are chatty because of its fine granularity. The high number of requests needed to accomplish non-trivial use cases can affect the performance of applications using such API's. This problem is particularly acute for mobile apps. See the [blog post](http://3scale.github.io/2013/04/18/accelerate-your-mobile-api-with-nginx-and-lua/) for some empirical results, for that particular case, requests time was reduced by a factor or 3.

**How?**

Instead of accessing the public methods of the API, a developer can create a lua script that has the full workflow for their use-case. This lua script can be run safely on the servers of the API provider (if they use API Aggregator, that is). 

The underlying idea is pretty much like **stored procedures for APIs**. 

Note that this approach is not unheard of. [Netflix](http://netflix.com), for instance, has a [JVM-based sandbox environment](http://techblog.netflix.com/2013/01/optimizing-netflix-api.html) so that their different development teams can create custom end-points for their specific needs on top of REST based API. With API Aggregator you can get quite close to the same design :-)


## ADDING API AGGREGATION SCRIPTS

To add a user generated script ("the stored procedure") you only need to drop the lua file to the directory defined in $lua_user_scripts_path.

After adding the script, the end-point will be dynamically generated in runtime and it will be immediately available.

The scripts must be unnamed functions, 

```lua
return function()
  -- magic goes here
  ngx.exit(ngx.HTTP_OK)
end
```

A example of a real user script,

```lua
return function()

  local max_sentiment = 5
  local params = ngx.req.get_query_args()
  local path = utils.split(ngx.var.request," ")[2]

  -- Get the sentence to be analyzed from the URL path
  local sentence = ngx.re.match(path,[=[^/aggr/positive_word/(.+).json]=])[1]
  sentence = utils.unescape(sentence)

  -- Do the REST API request to get the sentiment value of the sentence
  local res_sentence = ngx.location.capture("/v1/sentence/".. utils.escape(sentence) .. ".json" )
  local result = cjson.decode(res_sentence.body)

  -- If positive
  if (result["sentiment"]>0) then

    sentence = utils.unescape(sentence)

    local max = nil
    local words = utils.split(sentence," ")

    -- for each word in the sentence, do the REST API request to get the sentiment value of the 
    -- word
    for i,w in pairs(words) do
      local res_word = ngx.location.capture("/v1/word/".. utils.escape(w) .. ".json" )
      local word = cjson.decode(res_word.body)
      if max == nil or max < word.sentiment then
        max = word.sentiment
        result.highest_positive_sentiment_word = word
        if word.sentiment == max_sentiment then
          break
        end
      end
    end
  end

  ngx.header.content_type = "application/json"
  ngx.say(cjson.encode(result))
  ngx.exit(ngx.HTTP_OK)

end
```


This lua script aggregates 1+N requests to a REST API to serve a very particular use-case: to get the word with a highest positive emotional value of a sentence if it's positive. This use case is very specific to a particular application, so it should not be "public". 

However, being able to colocate the aggregator script with the API have multiple benefits for all parties involved:

  * For API consumers: it reduces the number of requests, thus reducing the page load time and if it's a mobile app, power consumption. Furthermore, it eliminates the need to run a backend services for your API to do exactly the type of aggregation that can be done now
  by the provider using API Aggregator.
  * For API providers, the bandwidth and the number of open connections is reduced. And what's more important, you are making your API very friendly
  to developers to use since they can create custom scripts that meet their particular use-cases.
  

After adding the lua script the developer can immediately access a new API endpoint named  _/aggr/positive_word/*.json__. This new API method does all the heavy-lifting against the REST API of the provider. 

The end-point is derived from the name of the lua file, or it can be customized on the configuration file.

## ARCHITECTURE

The diagram depicts the flow of the example that you can setup locally if you follow the HowTo Install section.

![Architecture Diagram](/data/architecture_diagram.png "Architecture Diagram")


## HOWTO INSTALL

### 1) Install Nginx with Lua Support 

You can add the lua module to your nginx or you can use the bundle OpenResty that has nginx with lua
(and other great extensions) already built-in.

For Debian/Ubuntu linux distribution you should install the following packages using apt-get:

    sudo apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl

For different systems check out the [OpenResty](http://openresty.org/#Installation) documentation.

Change VERSION with your desired version (we tested 1.2.3.8)

    wget http://agentzh.org/misc/nginx/ngx_openresty-VERSION.tar.gz
    tar -zxvf ngx_openresty-VERSION.tar.gz
    cd ngx_openresty-VERSION/

    ./configure --prefix=/opt/openresty --with-luajit --with-http_iconv_module -j2

    make
    make install
    
You can change the --prefix to set up your base directory.


### 2) Start the Nginx servers

**For the load balancer** (not needed in production)

You can start the Nginx that acts as load balancer (and that hosts the html5 app demo) like this:
    
    /opt/openresty/nginx/sbin/nginx -p `pwd`/lb/

This assumes you are on that in the base directory of the api-aggregation project. You can always replace 
the `pwd` with your full path to the _api-aggregator/lb_ directory.

Note that the nginx load balancer is not needed, you can use your own balancer. This is just included for convenience.

The HTML5 App demo is included in the load balancer (_lb/html/demo_). Once you run the load balancer, you can access it
at _localhost:8000/demo/_
    
To stop it. Just use the same line with `-s stop`

    /opt/openresty/nginx/sbin/nginx -p `pwd`/lb/ -s stop


**For the sandbox** 

The sandbox is not optional :-) It's where the lua scripts that do the API aggregation run. 

Before running the sandbox you must change the variable $lua_user_scripts_path to the full path of the lua user scripts
on the _sandbox/conf/nginx.conf_

    set $lua_user_scripts_path "/path/to/api-aggregator/sandbox/lua/user_scripts/";

All the user lua scripts that do API aggregation (the stored procedures) should be in the directory defined above. 

The name of the lua script is used to build the API endpoint, the URL. For instance, a script called _positive_word.lua_ 
will automatically be available at the end-point /aggr/positive_word/*. If you want an end-point /aggr/foo/ID.xml you will
 have to create a lua script called foo.lua. This convention is used to automatically map user scripts to API end-points, you
 can force arbitrary mappings using the directive _location_ of nginx.

Once you updated the _sandbox/conf/nginx.conf_ you can start it:

    /opt/openresty/nginx/sbin/nginx -p `pwd`/sandbox/

Again, you can stop it with `-s stop`

The sandbox is running on _localhost:8090_ (unless you change the listen port on the config file _api-aggregator/sandbox/conf/nginx.conf_)

### 3) Setup the SentimentAPI 

If you want, you can use the SentimentAPI instead of your own API. Installing it's quite straight forward:

    git clone 
    cd sentiment-api-example
    ruby ./sentiment-api.rb 8080
    
SentimentAPI is running on `localhost:8080`. You can test it with:

    curl -g "http://localhost:8080/v1/word/awesome.json"
    

### 4) Ready to go

Go to your browser to _localhost:8000/demo/_. You will get the HTML5 App demo that showcases the performance improvements
of API aggregation over direct REST access. Enjoy! 

## TROUBLESHOOTING

It's quit advisable to keep an eye on the error.log when trying it out, 

    tail -f */logs/error.log

## CONTRIBUTORS

* Josep M. Pujol (solso)
* Raimon Grau (kidd)    

## LICENSE

MIT License

Copyright (c) 2013 3scale



