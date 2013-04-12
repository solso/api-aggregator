

## API Aggregator

API Aggregator is a system that combines lua and nginx to have a sandboxed environment where you can safely run user generated scripts that do API aggregation. 

Why API aggregation? 

REST API's are chatty because of its fine granularity. The high number of requests needed to accomplish non-trivial use cases can affect the performance of applications using such API's. This problem is particularly acute for mobile apps. See the [blog post]() for some empirical results, for that particular case, requests time was reduced by a factor or 3.

How? 

Instead of accessing the public methods of the API, a developer can create a lua script that has the full workflow for their use-case. This lua script can be run safely on the servers of the API provider (if they use API Aggregator, that is). The underlying idea is pretty much like **stored procedures for APIs**. 


## Adding User Scripts

To add a user generated script ("the stored procedure") you only need to drop the lua file to the directory defined in $lua_user_scripts_path,

The scripts must be unnamed functions, 

<script src="https://gist.github.com/solso/5372568.js"></script>
  
A example of a proper user script,

<script src="https://gist.github.com/solso/5372559.js"></script>


The script above aggregates 1+N requests to a REST API to serve a very particular use-case: to get the word with a highest positive emotional value of a sentence if it's a positive sentence. This use case is very specific to a particular application, so it should not be "public". 

However, being able to colocate the aggregator script with the API have multiple benefits for all parties involved:

  * For API consumers: it reduces the number of requests, thus reducing the page load time and if it's a mobile app, power consumption. Furthermore, it eliminates the need to run a backend services for your API to do exactly the type of aggregation that can be done now
  by the provider using API Aggregator.
  * For API providers, the bandwidth and the number of open connections is reduced. And what's more important, you are making your API very friendly
  to developers to use since they can create custom scripts to do complex operations.
  

The developer of the application now, can have access to a new API endpoint called  _/aggr/postive_word/*.json__ that does all the heavy-lifting against the REST API of the provider. The result is a simpler and faster application.

The end-point is derived from the name of the lua file. The naming convention is defined.

## Architecture Diagram




## Intallation

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

The sandbox is running on _localhost:8090_ (unless you change the listen port on the config file _api-aggregator/sandbox/conf/nginx_as_sandbox.conf_)

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

## Troubleshotting

It's quit advisable to keep an eye on the error.log when trying it out, 

    tail -f */logs/error.log

## Contributors

* Josep M. Pujol (solso)
* Raimon Grau (kidd)    

## License

MIT License
Copyright (c) 2013 3scale



