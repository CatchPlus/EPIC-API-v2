=begin License
  Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  
      http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
=end


require 'rexml/document' # Used by HTTPStatus
require 'rack'
require 'thread' # Not sure why this is needed...


=begin rdoc
Library for creating ReSTful web services.
= Rationale
Confronted with the task of implementing a ReSTful web service in Ruby, I
checked out a number of existing libraries and frameworks, including
Ruby-on-Rails, and then decided to brew my own, the reason being that I couldn't
find a library or framework with all of the following properties:

* *Small* Some of these frameworks are really big. I need to get a job done in
  time. If understanding the framework takes more time than writing my own, I
  must at least feel confident that the framework I'm learning is more powerful
  that what I can come up with by myself. Ruby-on-Rails is probably the biggest
  framework out there, and it still lacks many features that are essential to
  ReSTful web service programming.

  This library is small. You could read _all_ the source code in less than an
  hour, and understand every detail.

* <b>No extensive tooling or code generation</b>. Code generation has been the
  subject of more than one flame-war over the years. Not much I can add to the
  debate. <em>But still,</em> with a language as dynamic as Ruby, you just
  shouldn't need code generation. Ever.

* <b>Full support for conditional requests</b> using +If-*:+ request headers. Most
  libraries' support is limited to +If-None-Match:+ and +If-Modified-Since:+
  headers, and only for +GET+ and +HEAD+ requests. For ReSTful web services,
  the +If-Match:+ and +If-Unmodified-Since:+ headers are at least as important,
  particularly for unsafe methods like +PUT+, +POST+, +PATCH+, and +DELETE+.

  This library fully supports the +ETag:+ and +Last-Modified:+ headers, and all
  +If-*:+ headers.

* <b>Resource centered</b>. Some libraries claim ReSTfulness, but at the same
  time have a servet-like interface, which requires you to implement method
  handles such as +doPOST(url)+. In these method handlers you have to find out
  what resource is posted to, depending on the URL.

  This library requires that you implement a Resource Factory which maps URIs
  to resource Objects. These objects will then receive HTTP requests.

= Hello World!
Here's a working example of a simple ReST server:

  # Filename: config.ru
  require 'rest'
  require 'digest/md5'
  
  # The class of the object we're going to serve:
  class Root
    include ReST::Resource
    def initialize *args 
      super
      @content = 'Hello world!'     
    end
    def do_GET request, response
      response['Content-Type'] = 'text/plain'
      response.write @content
    end
    def do_PUT request, response
      @content = request.body.read
      response.status = status_code :no_content
    end
    def etag
      '"' + Digest::MD5.new.update(@content).to_s + '"'
    end
  end
  $root_resource = Root.new '/'
  
  # ReST::Server needs a resource factory which can map URIs to resource objects:
  class ResourceFactory
    def [] uri
      case uri
      when '/';   $root_resource
      else;       nil
      end
    end
  end
  
  run ReST::Server.new ResourceFactory.new

If you'd save this file as +config.ru+, and run +rackup+, you should see
something like this:

  $> rackup
  [2012-07-10 11:45:32] INFO  WEBrick 1.3.1
  [2012-07-10 11:45:32] INFO  ruby 1.9.2 (2011-12-27) [java]
  [2012-07-10 11:45:32] INFO  WEBrick::HTTPServer#start: pid=5994 port=9292

Go with your browser to {http://localhost:9292/} and be greeted.

In this example, we implement +GET+ and +PUT+ requests for the resource at '/'. but
we get a few things for free:

==Free +OPTIONS+ response:
Request:

  OPTIONS / HTTP/1.1
  Host: localhost:9292

Response:

  HTTP/1.1 204 No Content 
  Allow: PUT, GET, HEAD, OPTIONS
  Date: Tue, 10 Jul 2012 10:22:52 GMT

As you can see, the server accurately reports all available methods for the
resource. Notice the availability of the +HEAD+ method; if you implement the
+GET+ method, you'll get +HEAD+ for free. It's still a good idea to explicitly
implement your own +HEAD+ request handler, especially for expensive resources,
when responding to a +HEAD+ request should be much more efficient than generating
a full +GET+ response, and strip off the response body.

==Free conditional request handling:
Let's first get the current state of the resource, with this request:

  GET / HTTP/1.1
  Host: localhost:9292

Response:

  HTTP/1.1 200 OK 
  Content-Type: text/plain
  Content-Length: 12
  ETag: "86fb269d190d2c85f6e0468ceca42a20"
  Date: Tue, 10 Jul 2012 10:34:36 GMT
  
  Hello world!

Now, we'd like to change the state of the resource, but only if it's still in
the state we last saw, to avoid the "lost update problem". To do that, we
produce an +If-Match:+ header, with the entity tag of our last version:

  PUT / HTTP/1.1
  Host: localhost:9292
  Content-Type: text/plain
  Content-Length: 31
  If-Match: "86fb269d190d2c85f6e0468ceca42a20"
  
  All your base are belong to us.

Response:

  HTTP/1.1 204 No Content
  ETag: "920c1e9267f923c62b55a471c1d8a528"
  Date: Tue, 10 Jul 2012 10:58:57 GMT

The response contains an +ETag:+ header, with the _new_ entity tag of this
resource. When we replay this request, we get the following response:

  HTTP/1.1 412 Precondition Failed
  Content-Type: text/html; charset="UTF-8"
  Date: Tue, 10 Jul 2012 11:06:54 GMT

  [...]
  <h1>HTTP/1.1 412 Precondition Failed</h1>
  <p>If-Match: "86fb269d190d2c85f6e0468ceca42a20"</p>
  [...]

The server returns with status <tt>412 Precondition Failed</tt>. In the HTML
response body, the server kindly points out exactly which precondition.

= Further reading
* {Server#initialize} for more information about your Resource Factory.
* {Resource#etag} and {Resource#last_modified} for more information on
  conditional requests.
* {Resource#do_METHOD} for more information about writing your own request
  handlers.
* {RelativeLocation} for more information about this piece of Rack middleware
  which allows you to return relative and absolute paths in the +Location:+
  response header, and why you'd want that.
@todo This should become a Ruby Gem some day.
@author Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>. Licensed under
  the Apache License 2.0. You should have received a copy of this license
  as part of this distribution.
=end
module ReST


=begin rdoc
An extension of {Array}.

To be used as an array of ETag strings. It overrides method {#===}.
@private
=end
class ETagArray < Array


=begin rdoc
Does any of the tags in +self+ match +etag+?
@param etag [#to_s]
@example
  etags = ETagArray.new [ 'W/"foo"', '"bar"' ]
  etags === '"foo"'
  #> true
@return [Boolean]
@see http://tools.ietf.org/html/rfc2616#section-13.3.3 RFC2616 section 13.3.3
  for details about weak and strong validator comparison.
=end
  def === etag
    etag = etag.to_s
    match = self.detect do
      |tag|
      tag = tag.to_s
      tag == '*' or
      tag == etag or
      'W/' +  tag == etag or
      'W/' + etag ==  tag
    end
    if  match and
        '*' != match and
        'W/' == etag[0,2] || 'W/' == match[0,2] and
        ! [ 'HEAD', 'GET' ].include? Request.current.request_method
      raise HTTPStatus, "BAD_REQUEST Weak validators are only allowed for GET and HEAD requests."
    end
    !!match
  end


end


=begin rdoc
Subclass of {Rack::Request}, augmented for ReSTful requests.
=end
class Request < Rack::Request


=begin rdoc
The resource factory for the current request.
@return [#[]]
@see Server#initialize
=end
  attr_reader :resource_factory


  def initialize resource_factory, *args
    super *args
    @resource_factory = resource_factory
  end


=begin rdoc
The request currently being processed in the current thread.

In a multi-threaded server, multiple requests can be handled at one time.
This method returns the request object, created (and registered) by
{Server#call!}
@return [Request]
=end
  def self.current
    Thread.current[:djinn_request]
  end

=begin rdoc
Assert all <tt>If-*</tt> request headers.
@return [void]
@raise [HTTPStatus] with one of the following status codes:
  [304 Not Modified]
  [400 Bad Request] Couldn't parse one or more <tt>If-*</tt> headers, or a
    weak validator comparison was requested for methods other than +GET+ or
    +HEAD+.
  [404 Not Found]
  [412 Precondition Failed]
  [501 Not Implemented] in case of +If-Range:+ header.
@see http://tools.ietf.org/html/rfc2616#section-13.3.3 RFC2616, section 13.3.3
  for details about weak and strong validator comparison.
@todo Implement support for the +If-Range:+ header.
=end
  def assert_if_headers resource
    raise HTTPStatus, 'NOT_IMPLEMENTED If-Range: request header is not supported.' \
      if @env.key? 'HTTP_IF_RANGE'
    empty = resource.empty?
    etag =          ( ! empty && resource.respond_to?(:etag)          ) ? resource.etag          : nil
    last_modified = ( ! empty && resource.respond_to?(:last_modified) ) ? resource.last_modified : nil
    cond = {
      :match => self.if_match,
      :none_match => self.if_none_match,
      :modified_since => self.if_modified_since,
      :unmodified_since => self.if_unmodified_since
    }
    allow_weak = ['GET', 'HEAD'].include? self.request_method
    if empty
      if cond[:match]
        raise HTTPStatus, "PRECONDITION_FAILED If-Match: #{@env['HTTP_IF_MATCH']}"
      elsif cond[:unmodified_since]
        raise HTTPStatus, "PRECONDITION_FAILED If-Unmodified-Since: #{@env['HTTP_IF_UNMODIFIED_SINCE']}"
      elsif cond[:modified_since]
        raise HTTPStatus, 'NOT_FOUND'
      end
    else
      if cond[:none_match] && cond[:none_match] === etag
        raise HTTPStatus, "PRECONDITION_FAILED If-None-Match: #{@env['HTTP_IF_NONE_MATCH']}"
      elsif cond[:match] && ! ( cond[:match] === etag )
        raise HTTPStatus, "PRECONDITION_FAILED If-Match: #{@env['HTTP_IF_MATCH']}"
      elsif cond[:unmodified_since]
        if ! last_modified || cond[:unmodified_since] < last_modified[0]
          raise HTTPStatus, "PRECONDITION_FAILED If-Unmodified-Since: #{@env['HTTP_IF_UNMODIFIED_SINCE']}"
        elsif last_modified && ! last_modified[1] && ! allow_weak &&
              cond[:unmodified_since] == last_modified[0]
          raise HTTPStatus,
                "PRECONDITION_FAILED If-Unmodified-Since: #{@env['HTTP_IF_UNMODIFIED_SINCE']}<br/>" +
                "Modification time is a weak validator for this resource."
        end
      elsif cond[:modified_since]
        if ! last_modified || cond[:modified_since] >= last_modified[0]
          raise HTTPStatus, 'NOT_MODIFIED'
        elsif last_modified && ! last_modified[1] && !allow_weak &&
              cond[:modified_since] == last_modified[0]
          raise HTTPStatus,
                "PRECONDITION_FAILED If-Modified-Since: #{@env['HTTP_IF_MODIFIED_SINCE']}<br/>" +
                "Modification time is a weak validator for this resource."
        end
      end
    end
  end


=begin rdoc
Hash of acceptable media types and their qualities.

This method parses the HTTP/1.1 +Accept:+ header. If no acceptable media
types are provided, an empty Hash is returned.
@return [Hash{media_type => quality}]
=end
  def accept
    @env['djinn.accept'] ||= begin
      Hash[
        @env['HTTP_ACCEPT'].to_s.split(',').collect do
          |entry|
          type, *options = entry.delete(' ').split(';')
          quality = 1
          options.each { |e|
            quality = e[2..-1].to_f if e.start_with? 'q='
          }
          [type, quality]
        end
      ]
    rescue
      {}
    end
  end # def accept


=begin rdoc
The best media type for the response body...

...given the client's +Accept:+ header(s) and the available representations
in the server.
@param content_types [Hash{media_type => quality}]
  indicating what media types can be provided by the server, with their
  relative qualities.
@param require_match [Boolean]
  Should this method throw an {HTTPStatus} exception
  <tt>406 Not Acceptable</tt> if there's no match.
@return [String]
@raise [HTTPStatus] <tt>406 Not Acceptable</tt>
@todo This method and its documentation seem to mix <b>content type</b> and
  <b>media type</b>. I think the implementation is good, only comparing
  <b>media types</b>, so all references to <b>content types</b> should be
  removed.
=end
  def best_content_type content_types, require_match = true
    return content_types.sort_by(&:last).last[0] if self.accept.empty?
    matches = []
    self.accept.each {
      |accept_type, accept_quality|
      content_types.each {
        |response_type, response_quality|
        mime_type = response_type.split(';').first.strip
        if File.fnmatch( accept_type, mime_type )
          matches.push [ response_type, accept_quality * response_quality ]
        end
      }
    }
    if matches.empty?
      raise HTTPStatus, 'NOT_ACCEPTABLE' if require_match
      nil
    else
      matches.sort_by(&:last).last[0]
    end
  end


  # @deprecated This method seems to be unused...
  def truthy? parameter
    value = self.GET[parameter] || ''
    %r{\A(1|t(rue)?|y(es)?|on)\z}i === value
  end


  # @deprecated This method seems to be unused...
  def falsy? parameter
    value = self.GET[parameter] || ''
    %r{\A(0|f(alse)?|n(o)?|off)\z}i === value
  end


=begin rdoc
@!method if_match()
Parses the HTTP/1.1 +If-Match:+ header.
@return [nil, Array<String>] Actually, the returned Array is an {ETagArray}.
@see http://tools.ietf.org/html/rfc2616#section-14.24 RFC2616, section 14.24
@see #if_none_match
=end
  def if_match none = false
    header = @env["HTTP_IF_#{ none ? 'NONE_' : '' }MATCH"]
    return nil unless header
    envkey = "djinn.if_#{ none ? 'none_' : '' }match"
    retval = ETagArray.new
    if %r{\A\s*\*\s*\z} === header
      retval << '*'
    elsif %r{\A(\s*(W/)?"([^"\\]|\\.)*"\s*,)+\z}m === ( header + ',' )
      header.scan( %r{(?:W/)?"(?:[^"\\]|\\.)*"}m ).each do
        |etag| retval << etag
      end
    else
      raise HTTPStatus, "BAD_REQUEST Couldn't parse If-#{ none ? 'None-' : '' }Match: #{header}"
    end
    retval
  end


=begin rdoc
Parses the HTTP/1.1 +If-None-Match:+ header.
@return [nil, Array<String>] Actually, the returned Array is an {ETagArray}.
@see http://tools.ietf.org/html/rfc2616#section-14.26 RFC2616, section 14.26
@see #if_match
=end
  def if_none_match
    self.if_match true
  end


=begin rdoc
@!method if_modified_since()
@return [nil, Time]
@see http://tools.ietf.org/html/rfc2616#section-14.25 RFC2616, section 14.25
@see #if_unmodified_since
=end
  def if_modified_since unmodified = false
    header = @env["HTTP_IF_#{ unmodified ? 'UN' : '' }MODIFIED_SINCE"]
    return nil unless header
    begin
      header = Time.httpdate( header )
    rescue ArgumentError
      raise HTTPStatus, "BAD_REQUEST Couldn't parse If-#{ unmodified ? 'Unmodified' : 'Modified' }-Since: #{header}"
    end
    header
  end


=begin rdoc
# @return [nil, Time]
# @see http://tools.ietf.org/html/rfc2616#section-14.28 RFC2616, section 14.28
# @see #if_modified_since
=end
  def if_unmodified_since
    self.if_modified_since true
  end


end # class Request


=begin rdoc
Mixin for resources served by {Server}.

{Server} helps you implement ReSTful resource objects quickly in a couple
of ways. {Server} doesn't require _any_ methods on a resource object. You
could safely provide <code>Object.new</code>, without causing an error. OK,
your resource wouldn't respond to any methods, but it wouldn't be an error
either.
Classes that include this module may implement a method +content_types+
for content negotiation. This method must return a hash of
<tt>mime-type => quality</tt> pairs. 
@see Server, ResourceFactory
=end
module Resource


  include Rack::Utils


=begin rdoc
@!method do_METHOD( Request, Rack::Response )
HTTP/1.1 method handler.

To handle certain HTTP/1.1 request methods, resources must implement methods
called +do_<HTTP_METHOD>+.
@example Handling +GET+ requests
  def do_GET request, response
    response['Content-Type'] = 'text/plain'
    response.body = [ 'Hello world!' ]
  end
@abstract
@return [void]
@raise [HTTPStatus, RuntimeError]
=end


  # The path of this resource.
  # @return [String]
  # @see #initialize
  attr_reader :path


  # @param path [#to_s] The path of this resource. This is a +path-absolute+ as
  #   defined in {RFC3986, section 3.3}[http://tools.ietf.org/html/rfc3986#section-3.3].
  # @see #path
  def initialize path
    @path = path.to_s
  end


=begin rdoc
Does this resource _exists_?

For example, a client can +PUT+ to a URL that doesn't refer to a resource
yet. In that case, your {Server#resource_factory resource factory} can
produce an empty resource to to handle the +PUT+ request. +HEAD+ and +GET+
requests will still yield <tt>404 Not Found</tt>.

@return [Boolean] The default implementation returns +false+.
=end
  def empty?
    false
  end


=begin rdoc
List of all HTTP/1.1 methods implemented by this resource.

This works by inspecting all the {#do_METHOD} methods this object implements.
@return [Array<Symbol>]
=end
  def http_methods
    unless @djinn_resource_http_methods
      @djinn_resource_http_methods = []
      self.public_methods.each do
        |public_method|
        if ( match = /\Ado_([A-Z]+)\z/.match( public_method ) )
          @djinn_resource_http_methods << match[1].to_sym
        end
      end
      @djinn_resource_http_methods.delete :HEAD \
        unless @djinn_resource_http_methods.include? :GET
    end
    @djinn_resource_http_methods
  end


=begin rdoc
Handles a HEAD request.

As a courtesy, this module implements a default handler for HEAD requests,
which calls {#do_METHOD #do_GET}, and then strips of the response body.

If this resource implements method +content_types+, then <code>response['Content-Type']</code>
will be set in the response object passed to {#do_METHOD #do_GET}.

Feel free to override this method at will.
@return [void]
@raise [HTTPStatus]
  [<tt>405 Method Not Allowed</tt>]
    if the resource doesn't implement the +GET+ method.
=end
  def do_HEAD request, response
    raise ReST::HTTPStatus, 'METHOD_NOT_ALLOWED ' +  self.http_methods.join( ' ' ) \
      unless self.respond_to? :do_GET
    self.do_GET request, response
    response['Content-Length'] =
      response.body.reduce(0) do
        |memo, s| memo + bytesize(s)
      end.to_s
    response.body = []
  end


=begin rdoc
Handles an OPTIONS request.

As a courtesy, this module implements a default handler for OPTIONS
requests. It creates an +Allow:+ header, listing all implemented HTTP/1.1
methods for this resource. By default, an <tt>HTTP/1.1 204 No Content</tt> is
returned (without an entity body).

Feel free to override this method at will.
@return [void]
@raise [HTTPStatus] [<tt>404 Not Found</tt>] if this resource is empty.
=end
  def do_OPTIONS request, response
    raise ReST::HTTPStatus, 'NOT_FOUND' if self.empty?
    response.status = status_code :no_content
    response.header['Allow'] = self.http_methods.join ', '
  end


=begin rdoc
@!attribute [r] etag
The ETag of this resource.

If your classes implement this method, then an +ETag:+ response
header is generated automatically when appropriate. This allows clients to
perform conditional requests, by sending an +If-Match:+ or
+If-None-Match:+ request header. These conditions are then asserted
for you automatically.

Make sure your entity tag is a properly formatted string. In ABNF:
  entity-tag = [ "W/" ] quoted-string
@abstract
@return [String]
@see http://tools.ietf.org/html/rfc2616#section-14.19 RFC2616 section 14.19
=end


=begin rdoc
@!attribute [r] last_modified
Last modification of this resource.

If your classes implement this method, then a +Last-Modified:+ response
header is generated automatically when appropriate. This allows clients to
perform conditional requests, by sending an +If-Modified-Since:+ or
+If-Unmodified-Since:+ request header. These conditions are then asserted
for you automatically.
@abstract
@return [Array<(Time, Boolean)>] The timestamp, and a flag indicating if the
  timestamp is a strong validator.
@see http://tools.ietf.org/html/rfc2616#section-14.29 RFC2616 section 14.29
=end


=begin rdoc
Wrapper around {#do_HEAD}
@private
@return [void]
@raise [HTTPStatus] [<tt>404 Not Found</tt>] if this resource is empty.
=end
  def http_HEAD request, response
    raise ReST::HTTPStatus, 'NOT_FOUND' if self.empty?
    self.do_HEAD request, response
  end


=begin rdoc
Wrapper around {#do_METHOD #do_GET}
@private
@return [void]
@raise [HTTPStatus]
  [<tt>404 Not Found</tt>] if this resource is empty.
  [<tt>405 Method Not Allowed</tt>] if the resource doesn't implement the +GET+ method.
=end
  def http_GET request, response
    raise ReST::HTTPStatus, 'NOT_FOUND' if self.empty?
    raise ReST::HTTPStatus, 'METHOD_NOT_ALLOWED ' +  self.http_methods.join( ' ' ) \
      unless self.respond_to? :do_GET
    self.do_GET request, response
  end


=begin rdoc
Wrapper around {#do_METHOD #do_PUT}
@private
@return [void]
@raise [HTTPStatus]
  [<tt>405 Method Not Allowed</tt>] if the resource doesn't implement the +PUT+ method.
=end
  def http_PUT request, response
    raise ReST::HTTPStatus, 'METHOD_NOT_ALLOWED ' +  self.http_methods.join( ' ' ) \
      unless self.respond_to? :do_PUT
    self.do_PUT request, response
  end


end # module Resource


=begin rdoc
This class has a dual nature. It inherits from RuntimeError, so that it may
be used together with #raise.
=end
class HTTPStatus < RuntimeError


  include Rack::Utils


  attr_reader :response


  # The general format of +message+ is: +<status> [ <space> <message> ]+
  def initialize( message )
    @response = Rack::Response.new
    matches = %r{\A(\S+)\s*(.*)\z}m.match(message.to_s)
    status = status_code(matches[1].downcase.to_sym)
    @response.status = status
    message = matches[2]
    case status
    when 201, 301, 302, 303, 305, 307
      message = message.split /\s+/
      case message.length
      when 0
        message = ''
      when 1
        @response.header['Location'] = message[0]
        message = "<p><a href=\"#{message[0]}\">#{escape_html(unescape message[0])}</a></p>"
      else
        message = '<ul>' + message.collect {
          |url|
          "\n<li><a href=\"#{url}\">#{escape_html(unescape url)}</a></li>"
        }.join + '</ul>'
      end
    when 405 # Method not allowed
      message = message.split /\s+/
      @response.header['Allow'] = message.join ', '
      message = '<h2>Allowed methods:</h2><ul><li>' +
        message.join('</li><li>') + '</li></ul>'
    when 406 # Unacceptable
      message = message.split /\s+/
      message = '<h2>Available representations:</h2><ul><li>' +
        message.join('</li><li>') + '</li></ul>'
    when 415 # Unsupported Media Type
      message = message.split /\s+/
      message = '<h2>Supported Media Types:</h2><ul><li>' +
        message.join('</li><li>') + '</li></ul>'
    end
    super message
    begin
      REXML::Document.new \
        '<?xml version="1.0" encoding="UTF-8" ?>' +
        '<div>' + message + '</div>'
    rescue
      message = escape_html message
    end
    message = "<p>#{message}</p>" unless '<' == message[0, 1]
    message = message.gsub( %r{\n}, "<br/>\n" )
    @response.header['Content-Type'] = 'text/html; charset="UTF-8"'
    @response.body = [ self.class.template.call( status, message ) ]
  end


  DEFAULT_TEMPLATE = lambda do
    | status_code, xhtml_message |
    status_code = status_code.to_i
    xhtml_message = xhtml_message.to_s
    <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>HTTP/1.1 #{status_code.to_s} #{HTTP_STATUS_CODES[status_code]}</title>
  </head>
  <body>
    <h1>HTTP/1.1 #{status_code.to_s} #{HTTP_STATUS_CODES[status_code]}</h1>
#{xhtml_message}
  </body>
</html>
EOS
  end


=begin rdoc
The passed block must accept two arguments:
1. *int* a status code
2. *string* an xhtml fragment
and return a string
=end
  def self.template(&block)
    @template ||= ( block || DEFAULT_TEMPLATE )
  end


end


=begin rdoc
Rack middleware, inspired by {Rack::RelativeRedirect}.

This middleware allows you to return a path your +Location:+ response header.
This was common practice in HTTP/1.0, but HTTP/1.1 requires a full URI in the
+Location:+ header. This middleware automatically translates your absolute path
to a full URI.

Differences with {Rack::RelativeRedirect}:
- uses Rack::Utils::base_uri for creating absolute URIs.
- the +Location:+ header, if present, is always rectified, independent of the
  HTTP status code.
- relative paths (such as +../../some/path+) are not supported.
=end
class RelativeLocation


  def initialize(app)
    @app = app
  end


=begin rdoc
Call the next middleware with the environment.

If the +Location:+ header is a +path-absolute+ as defined in
{http://tools.ietf.org/html/rfc3986#section-3.3 RFC3986, section 3.3}, then
prepend the current scheme, server name, and port, to constitute a full URI.
=end
  def call(env)
    res = @app.call(env)
    if ( location = res[1]['Location'] ) and
       ! %r{\A[a-z]+://}.match(location)
      request = Rack::Request.new env
      unless '/' == location[0, 1]
        path = request.path.dup
        path[ %r{[^/]*\z} ] = ''
        location = File.expand_path( location, path )
      end
      res[1]['Location'] = request.base_url + location
    end
    res
  end


end # RelativeLocation


=begin rdoc
# Rack compliant server class for implementing RESTful web services.
=end
class Server


=begin rdoc
An object responding thread safely to method +#[]+.

A {Server} has no knowledge, and makes no presumptions, about your URI namespace.
It requires a <em>Resource Factory</em> which produces {Resource Resources} given
a certain absolute path.

The Resource Factory you provide need only implement one method, with signature
<b><code>Resource #[]( String path )</code></b>.
This method will be called with a URI-encoded path string, and must return a
{Resource}, or <code>nil</code> if there's no resource at the given path.

For example, if a ReST client
tries to access a resource with URI {http://example.com/your/resource http://example.com/some/resource},
then your Resource Factory can expect to be called like this:
  resource = resource_factory[ '/your/resource' ]

If there's no resource at the given path, but you'd still like to respond to
+POST+ or +PUT+ requests to this path, you must return an
{Resource#empty? empty resource}.
@return [#[]]
@see #initialize
=end
  attr_reader :resource_factory


=begin rdoc
{include:#resource_factory}
=end
  def initialize(resource_factory)
    super()
    @resource_factory = resource_factory
  end


=begin rdoc
As required by the Rack specification.

For thread safety, this method clones +self+, which handles the request in
{#call!}. A similar approach is taken by the Sinatra library.
@return [Array<(status_code, response_headers, response_body)>]
=end
  def call(p_env)
    start = Time.now
    retval = dup.call! p_env
    $stderr.puts( 'Duration: ' + ( Time.now - start ).to_s )
    retval
  end

=begin rdoc
@return [Array<(status_code, response_headers, response_body)>]
=end
  def call!(p_env)
    request  = ReST::Request.new( resource_factory, p_env )
    # See also Request::current():
    Thread.current[:djinn_request] = request
    begin
      response = Rack::Response.new
      begin
        raise HTTPStatus, 'NOT_FOUND' \
          unless resource = self.resource_factory[request.path]
        response.header['Content-Location'] = request.base_url + resource.path \
          unless resource.path == request.path
        request.assert_if_headers resource
        if resource.respond_to? :"http_#{request.request_method}"
          resource.__send__( :"http_#{request.request_method}", request, response )
        elsif resource.respond_to? :"do_#{request.request_method}"
          resource.__send__( :"do_#{request.request_method}", request, response )
        else
          raise HTTPStatus, 'METHOD_NOT_ALLOWED ' + resource.http_methods.join( ' ' )
        end
      rescue HTTPStatus
        response = $!.response
        raise if 500 == response.status
        # The next line fixes a small peculiarity in RFC2616: the response body of
        # a +HEAD+ request _must_ be empty, even for responses outside 2xx.
        if request.head?
          response.body = []
          response['Content-Length'] = '0'
        end
      end
      if  201 == response.status &&
          ( location = response['Location'] ) &&
          ( new_resource = request.resource_factory[location] ) &&
          ! new_resource.empty? \
      or  ( (200...300) === response.status ||
             304        ==  response.status ) &&
          ! response['Location'] &&
          ( new_resource = request.resource_factory[request.path] ) &&
          ! new_resource.empty?
        set_default_headers new_resource, response
      end
      response.finish
    ensure
      Thread.current[:djinn_request] = nil
    end # begin
  end


private


=begin rdoc
Adds +ETag:+ and +Last-Modified:+ response headers.
=end
  def set_default_headers resource, response
    if ! response.include?( 'ETag' ) &&
       resource.respond_to?( :etag )
      response['ETag'] = resource.etag
    end
    if ! response.include?( 'Last-Modified' ) &&
       resource.respond_to?( :last_modified )
      response['Last-Modified'] = resource.last_modified[0].httpdate
    end
  end


end # class Server


end # module ReST
