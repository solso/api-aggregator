

## 

## Howto

### 2) Install Nginx with Lua Support 

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


### 3) Start the Nginx servers

* **For the load balancer** (not needed in production)

You can start the Nginx that acts as load balancer (and that hosts the html5 app demo) like this:
    
    /opt/openresty/nginx/sbin/nginx -p `pwd`/lb/

This assumes you are on that in the base directory of the api-aggregation project. You can always replace 
the `pwd` with your full path to the _api-aggregator/lb_ directory.

Note that the nginx load balancer is not needed, you can use your own balancer. This is just included for convenience.

The HTML5 App demo is included in the load balancer (_lb/html/demo_). Once you run the load balancer, you can access it
at _localhost:8000/demo/_
    
To stop it. Just use the same line with `-s stop`

    /opt/openresty/nginx/sbin/nginx -p `pwd`/lb/ -s stop


* **For the sandbox** 

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

### 4) Setup the SentimentAPI 

If you want, you can use the SentimentAPI instead of your own API. Installing it's quite straight forward:

    git clone 
    cd sentiment-api-example
    ruby ./sentiment-api.rb 8080
    
SentimentAPI is running on `localhost:8080`. You can test it with:

    curl -g "http://localhost:8080/v1/word/awesome.json"
    

### 5) Ready to go

Go to your browser to _localhost:8000/demo/_. You will get the HTML5 App demo that showcases the performance improvements
of API aggregation over direct REST access. Enjoy! 

## Troubleshotting

It's quit advisable to keep an eye on the error.log when trying it out, 

    tail -f */logs/error.log
    

## License



