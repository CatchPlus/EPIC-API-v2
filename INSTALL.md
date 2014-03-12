Installation
============

Requirements
------------
### compilers
For the compilation of JRuby several compilers are needed. They can be installed in several ways.
The compilers needed are: 
`git gcc gcc-c++ ant`

### apache
The software requires apache/httpd daemon.
The apache/httpd parts needed are:
`apache-tomcat-apis mod_ssl`

### password generator
A password is needed for the epic users. Included in the EPIC API is a script which generates passwords. It depends on the following tool:
`pwgen`

### Handle System v7
You'll need a running Handle System installation.
Details can be found at the [Handle System web site](http://www.handle.net/).
The handle system needs to be installed with a mysql database. 


The web service needs to know the location of your Handle System installation.
Create a symbolic link inside the Web Service top level directory called `hsj`, pointing to `$HS_DISTRO_ROOT/lib`.

### JRuby
First of all, this software requires JRuby, as it interfaces with the Java client library of the Handle System.
JRuby can be installed in many ways.
You can go to the [JRuby web site](http://jruby.org/) and download it from there.
The developers of this software prefer using the [Ruby Version Manager (RVM)](http://beginrescueend.com/) for managing multiple Ruby installations on a single machine, and for managing multiple gemsets. Perform the following actions NOT as the user root.

Install RVM

    cd ~
    curl -L https://get.rvm.io | bash -s stable --without-gems="rvm rubygems-bundler"

Source rvm commands (or logout/login) or

    source .rvm/scripts/rvm
    
NOTE: If you encounter a problem when installing RVM under Ubuntu please run following steps

    sudo apt-get --purge remove ruby-rvm
    sudo rm -rf /usr/share/ruby-rvm /etc/rvmrc /etc/profile.d/rvm.sh
and then try installing RVM as mentioned above.

Install jRuby

    rvm install jruby-1.6.7.2
    rvm use jruby-1.6.7.2

Create a gemset

    rvm gemset create epic_prod
    rvm use 'jruby-1.6.7.2@epic_prod'


After installing JRuby, make sure that the interpreter runs in _1.9_ _mode_.
This is done by adding option `--1.9` to environment variable `JRUBY_OPTS`. An example for `.bashrc` is:
    export JRUBY_OPTS="--1.9 -J-Djruby.thread.pool.enabled=true"
     
If you use `RVM`, you might consider using an `.rvmrc` document.
There's an example of such a document in the distribution, by executing

    rvm rvmrc

inside the root of this distribution.

After this install the necessary gems


### Sequel
Sequel is a Ruby database abstraction layer and Object-Relational Mapper (ORM).
For performance reasons, we don't use the ORM features.

Installing `sequel` is easy:

    gem install sequel

Depending on the kind of database you're using underneath the Handle System,
you'll probably need to install some database handler as well.
The service developers use gem `jdbc-mysql` in order to connect to their
MySQL databases.

    gem install jdbc-mysql 

### Rack
Rack provides a minimal, modular and adaptable interface for developing web
applications in Ruby. By wrapping HTTP requests and responses in the simplest way 
possible, it unifies and distills the API for web servers, web frameworks, and 
software in between (the so-called middleware) into a single method call.
Also see http://rack.github.com/. 

installing `rack` is easy:

    gem install rack

### Rackful
[Rackful](http://pieterb.github.com/Rackful/) is a library to build ReSTful web
services on top of [Rack](http://rack.rubyforge.org/doc/).

You might want to read the
[Rack interface specification](http://rack.rubyforge.org/doc/SPEC.html)
and [other Rack documentation]() as well.

    gem install rackful

### Mizuno
mizuno are a pair of Jetty-powered running shoes for JRuby/Rack.

installing `mizuno` is easy:

    gem install mizuno

### Json_pure
This is a JSON implementation in pure Ruby.

installing `json_pure` is easy:

    gem install json_pure

### Choice
Choice is a simple little gem for easily defining and parsing command line options with a friendly DSL.

installing `choice` is easy:

    gem install choice

### Other needed gems
The following gems are also needed:

    gem install childprocess
    gem install ffi


Installation
------------
The EPIC API is installed as follows:

### EPIC API
create a directory and unzip the package in that directory (Not as the user root). An example would be:

    cd ~
    unzip EPIC_API in to $HOME/epic_prod

modify epic_prod/.rvmrc so it uses the correct gems.

    environment_id="jruby-1.6.7.2@epic_prod"

create links to the correct directory's.

	cd epic_prod
	ln -s $HOME/.rvm/gems/jruby-1.6.7.2@epic_prod/gems gems
    ln -s <directory_handle_service>/hsj7/lib hsj
    ln -s gems/rackful-0.1.3 rackful


Configuration
-------------

The web service comes preconfigured for HTTP Digest authentication.
You'll need to create two configuration files for this to work, though:

### General configuration
The default installation expects some configuration information in file `config.rb`.
You'll find a sample configuration file called `config.rb.example` in the distribution.
Copy or rename this file to `config.rb` and edit it to your situation:

    cp -a config.rb.example config.rb
    $EDITOR config.rb

The config.rb has the connection details to the database for instance. It has been 
developed against mysql. So that's what supported. The first line in config.ru can
have the port on which the epic server listens. It is in the format of:

    #\ --port 9292 --server mizuno

The default installation expects some configuration information in file `config.ru`.
You'll find a sample configuration file called `config.ru.example` in the distribution.
Copy or rename this file to `config.ru` and edit it to your situation:

    cp -a config.ru.example config.ru
    $EDITOR config.ru


### User accounts
In the default configuration, account information is expected in file `secrets/users.rb`.
From the installation root, do the following:

    cd secrets/
    cp -a users.rb.example users.rb
    $EDITOR users.rb

The passwords are hashed in the field "digest". It is the MD5 checksum of "<username>:EPIC:<password>".

For the communication with the handle service a key has to be present in the `secrets` directory.
It must have the format `300_0_NA_prefix`

an example is following:

    300_0_NA_prefix -> <handle_configuration_directory>/privkey.bin

### Apache 

The file /etc/httpd/conf.d/ssl.conf has the following addition.

    ProxyPass /v2/ http://localhost:9292/
    ProxyPassReverse /v2/ http://localhost:9292/
    ProxyPassReverseCookieDomain localhost:9922 <fully_qualified_hostname>
    ProxyPassReverseCookiePath / /v2/

Apache acts as a proxy. HTTPS traffic is routed to localhost port 9292. This 
is the port where the epic server v2 listens. So everything which starts with /v2/ is
routed/proxied to the EPIC service.

If Apache is used modify config.ru to have the correct url returned:

    # When run behind an Apache reverse proxy server, the original request scheme
    # (http or https) gets lost. This config works around this for epic_1.0.0:
    #use Rack::Config do
    #  |env|
    #  env['HTTP_X_FORWARDED_SSL'] = 'on'
    #end
    use Rack::Config do
      |env|
      env.keys.each do
        |key|
        env.delete(key) if /^http_x_forwarded_/i === key
      end
    end


Running!
--------

At this point, you should be able to start the web service:

    rackup

By default, this will start a Webrick web server, listening to port 9292.

If you'd like to use another web server, another port number, another authentication method,
then check out the Rack documentation,
and start editing the rackup configuration file `config.ru`.
That files contains a lot of in-line documentation that hopefully gets you started.

At this time a https request can be done to: `https://<fully_qualified_hostname>/v2/handles/`


