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


# Library for creating ReSTful web services.
# @todo This should become a Ruby Gem some day.
# @see ReST::Server
module ReST


# An extension of {Array}.
#
# Should be used as an array of ETag strings. It overrides method {#===}.
# @private
class ETagArray < Array


  # Does any of the tags in +self+ match +etag+?
  # @param etag [#to_s]
  # @example
  #   etags = ETagArray.new [ 'W/"foo"', '"bar"' ]
  #   etags === '"foo"'
  #   #> true
  # @return [Boolean]
  # @see http://tools.ietf.org/html/rfc2616#section-13.3.3 RFC2616 section 13.3.3
  def === etag
    etag = etag.to_s
    allow_weak = [ 'HEAD', 'GET' ].include? Request.current.request_method
    self.any? do
      |tag|
      tag = tag.to_s
      raise HTTPStatus, "BAD_REQUEST Weak validators, such as #{tag}, are only allowed for GET and HEAD requests." \
        if 'W/' == tag[0,2] && !allow_weak
      tag == '*' or
      tag == etag or
      allow_weak && (
        'W/' +  tag == etag ||
        'W/' + etag ==  tag
      )
    end
  end


end


# Subclass of {Rack::Request}, augmented for ReSTful requests.
# @todo Is this the best way of augmenting an existing class? In ruby, we could
#   also write a module instead of a derived class, and then insert this module
#   in each {Rack::Request}'s metaclass.
class Request < Rack::Request


  # The request currently being processed in the current thread.
  #
  # In a multi-threaded server, multiple requests can be handled at one time.
  # This method returns the request object, created (and registered) by
  # {Server#call!}
  # @return [Request]
  def self.current
    Thread.current[:djinn_request]
  end


  # Assert all <tt>If-*</tt> request headers.
  # @return [void]
  # @raise [HTTPStatus] with one of the following status codes:
  #   [304 Not Modified]
  #   [400 Bad Request] Couldn't parse one or more <tt>If-*</tt> headers, or a
  #     weak validator comparison was requested for methods other than +GET+ or
  #     +HEAD+.
  #   [404 Not Found]
  #   [412 Precondition Failed]
  #   [501 Not Implemented] in case of +If-Range:+ header.
  # @see http://tools.ietf.org/html/rfc2616#section-13.3.3 RFC2616, section 13.3.3
  #   for details about weak and strong validator comparison.
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


  # Hash of acceptable media types and their qualities.
  #
  # This method parses the HTTP/1.1 +Accept:+ header. If no acceptable media
  # types are provided, an empty Hash is returned.
  # @return [Hash{media_type => quality}]
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


  # The best media type for the response body...
  #
  # ...given the client's +Accept:+ header(s) and the available representations
  # in the server.
  # @param content_types [Hash{media_type => quality}]
  #   indicating what media types can be provided by the server, with their
  #   relative qualities.
  # @param require_match [Boolean]
  #   Should this method throw an {HTTPStatus} exception
  #   <tt>406 Not Acceptable</tt> if there's no match.
  # @return [String]
  # @raise [HTTPStatus] <tt>406 Not Acceptable</tt>
  # @todo This method and its documentation seem to mix <b>content type</b> and
  #   <b>media type</b>. I think the implementation is good, only comparing
  #   <b>media types</b>, so all references to <b>content types</b> should be
  #   removed.
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


  # @!method if_match()
  # Parses the HTTP/1.1 +If-Match:+ header.
  # @return [nil, Array<String>] Actually, the returned Array is an {ETagArray}.
  # @see http://tools.ietf.org/html/rfc2616#section-14.24 RFC2616, section 14.24
  # @see #if_none_match
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


  # Parses the HTTP/1.1 +If-None-Match:+ header.
  # @return [nil, Array<String>] Actually, the returned Array is an {ETagArray}.
  # @see http://tools.ietf.org/html/rfc2616#section-14.26 RFC2616, section 14.26
  # @see #if_match
  def if_none_match
    self.if_match true
  end


  # @!method if_modified_since()
  # @return [nil, Time]
  # @see http://tools.ietf.org/html/rfc2616#section-14.25 RFC2616, section 14.25
  # @see #if_unmodified_since
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


  # @return [nil, Time]
  # @see http://tools.ietf.org/html/rfc2616#section-14.28 RFC2616, section 14.28
  # @see #if_modified_since
  def if_unmodified_since
    self.if_modified_since true
  end


=begin
  # Validates the HTTP/1.1 +If-Match:+ header.
  #
  # If the client didn't specify an +If-Match:+ header, this method returns
  # true. Otherwise, the header is evaluated against *etag*, which must be the
  # ETag of the currently addressed resource.
  # @!method if_match(etag)
  # @param etag [#to_s]
  # @return [Boolean]
  # @see http://tools.ietf.org/html/rfc2616#section-14.24 RFC2616, section 14.24
  # @see #if_none_match
  # @todo This method is now called by {Resource#assert_if_headers}, which 
  #   provides the *etag* and contains a fair amount of logic. Wouldn't it be nice
  #   if that would all be contained in this method, and called from
  #   {Server#call!}?
  def if_match etag, none = false
    header = @env["HTTP_IF_#{ none ? 'NONE_' : '' }MATCH"]
    return true unless header
    envkey = "djinn.if_#{ none ? 'none_' : '' }match"
    @env[envkey] ||=
      if %r{\A\s*\*\s*\z} === header
        ['*']
      elsif %r{\A(\s*(W/)?"([^"\\]|\\.)*"\s*,)+\z}m === ( header + ',' )
        header.scan %r{(?:W/)?"(?:[^"\\]|\\.)*"}m
      else
        raise HTTPStatus, "BAD_REQUEST Couldn't parse If-#{ none ? 'None-' : '' }Match: #{header}"
      end
    any = @env[envkey].any? do
      |tag|
             tag == '*'         ||
             tag ==        etag ||
      'W/' + tag ==        etag ||
             tag == 'W/' + etag
    end
    any ^ none
  end


  # @see #if_match
  def if_none_match etag
    self.if_match etag, true
  end


  # Validates the HTTP/1.1 +If-Modified:+ header.
  #
  # If the client didn't specify an +If-Modified-Since:+ header, this method returns
  # true. Otherwise, the header is evaluated against *time*, which must be the
  # time the current resource was last modified (and which is returned in the
  # HTTP/1.1 +Last-Modified:+ response header).
  # @!method if_modified_since(time)
  # @param time [Time]
  # @return [Boolean]
  # @see http://tools.ietf.org/html/rfc2616#section-14.25 RFC2616, section 14.25
  # @see #if_unmodified_since
  # @todo This method is now called by {Resource#assert_if_headers}, which 
  #   provides the *time* and contains a fair amount of logic. Wouldn't it be nice
  #   if that would all be contained in this method, and called from
  #   {Server#call!}?
  def if_modified_since time, unmodified = false
    header = @env["HTTP_IF_#{ unmodified ? 'UN' : '' }MODIFIED_SINCE"]
    return true unless header
    header = Time.httpdate( header )
    modified = time > header
    modified ^ unmodified
  end


  # @see #if_modified_since
  def if_unmodified_since time
    self.if_modified_since time, true
  end
=end


end # class Request


# Mixin for resources served by {Server}.
#
# {Server} helps you implement ReSTful resource objects quickly in a couple
# of ways. {Server} doesn't require _any_ methods on a resource object. You
# could safely provide <code>Object.new</code>, without causing an error. OK,
# your resource wouldn't respond to any methods, but it wouldn't be an error
# either.
# Classes that include this module may implement a method +content_types+
# for content negotiation. This method must return a hash of
# <tt>mime-type => quality</tt> pairs. 
# @see Server, ResourceFactory
module Resource


  include Rack::Utils


  # @!method do_METHOD( Request, Rack::Response )
  # HTTP/1.1 method handler.
  #
  # To handle certain HTTP/1.1 request methods, resources must implement methods
  # called +do_<HTTP_METHOD>+.
  # @example Handling +GET+ requests
  #   def do_GET request, response
  #     response['Content-Type'] = 'text/plain'
  #     response.body = [ 'Hello world!' ]
  #   end
  # @abstract
  # @return [void]
  # @raise [HTTPStatus, RuntimeError]


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


  # Does this resource _exists_?
  #
  # For example, a client can +PUT+ to a URL that doesn't refer to a resource
  # yet. In that case, your {Server#resource_factory resource factory} can
  # produce an empty resource to to handle the +PUT+ request. +HEAD+ and +GET+
  # requests will still yield <tt>404 Not Found</tt>.
  #
  # @return [Boolean] The default implementation returns +false+.
  def empty?
    false
  end


  # List of all HTTP/1.1 methods implemented by this resource.
  #
  # This works by inspecting all the {#do_METHOD} methods this object implements.
  # @return [Array<Symbol>]
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


  # Handles a HEAD request.
  #
  # As a courtesy, this module implements a default handler for HEAD requests,
  # which calls {#do_METHOD #do_GET}, and then strips of the response body.
  #
  # If this resource implements method +content_types+, then <code>response['Content-Type']</code>
  # will be set in the response object passed to +do_GET+.
  #
  # Feel free to override this method at will.
  # @return [void]
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


  # Handles an OPTIONS request.
  #
  # As a courtesy, this module implements a default handler for OPTIONS
  # requests. It creates an +Allow:+ header, listing all implemented HTTP/1.1
  # methods for this resource. By default, an <tt>HTTP/1.1 204 No Content</tt> is
  # returned (without an entity body).
  #
  # Feel free to override this method at will.
  # @return [void]
  def do_OPTIONS request, response
    raise ReST::HTTPStatus, 'NOT_FOUND' if self.empty?
    response.status = status_code :no_content
    response.header['Allow'] = self.http_methods.join ', '
  end


  # @!attribute [r] etag
  # The ETag of this resource.
  #
  # If your classes implement this method, then an +ETag:+ response
  # header is generated automatically when appropriate. This allows clients to
  # perform conditional requests, by sending an +If-Match:+ or
  # +If-None-Match:+ request header. These conditions are then asserted
  # for you automatically.
  #
  # Make sure your entity tag is a properly formatted string. In ABNF:
  #   entity-tag = [ "W/" ] quoted-string
  # @abstract
  # @return [String]
  # @see http://tools.ietf.org/html/rfc2616#section-14.19 RFC2616 section 14.19


  # @!attribute [r] last_modified
  # Last modification of this resource.
  #
  # If your classes implement this method, then a +Last-Modified:+ response
  # header is generated automatically when appropriate. This allows clients to
  # perform conditional requests, by sending an +If-Modified-Since:+ or
  # +If-Unmodified-Since:+ request header. These conditions are then asserted
  # for you automatically.
  # @abstract
  # @return [Array<(Time, Boolean)>] The timestamp, and a flag indicating if the
  #   timestamp is a strong validator.
  # @see http://tools.ietf.org/html/rfc2616#section-14.29 RFC2616 section 14.29


  # Wrapper around {#do_HEAD}
  # @private
  # @return [void]
  def http_HEAD request, response
    raise ReST::HTTPStatus, 'NOT_FOUND' if self.empty?
    self.do_HEAD request, response
    self.set_default_headers response
  end


  # Wrapper around {#do_GET}
  # @private
  # @return [void]
  def http_GET request, response
    raise ReST::HTTPStatus, 'NOT_FOUND' if self.empty?
    raise ReST::HTTPStatus, 'METHOD_NOT_ALLOWED ' +  self.http_methods.join( ' ' ) \
      unless self.respond_to? :do_GET
    self.do_GET request, response
    self.set_default_headers response
  end


  # Wrapper around {#do_PUT}
  # @private
  # @return [void]
  def http_PUT request, response
    raise ReST::HTTPStatus, 'METHOD_NOT_ALLOWED ' +  self.http_methods.join( ' ' ) \
      unless self.respond_to? :do_PUT
    self.do_PUT request, response
    if [ 200, 201, 204 ].include? response.status
      self.set_default_headers response
    end
  end


  # Called by {#http_GET} and {#http_HEAD}
  #
  # Adds +ETag:+ and +Last-Modified:+ response headers.
  # @private
  def set_default_headers response
    if ! response.include?( 'ETag' ) &&
       self.respond_to?( :etag )
      response['ETag'] = self.etag
    end
    if ! response.include?( 'Last-Modified' ) &&
       self.respond_to?( :last_modified )
      response['Last-Modified'] = self.last_modified[0].httpdate
    end
  end


end # module Resource


# This class has a dual nature. It inherits from RuntimeError, so that it may
# be used together with #raise.
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
    @response.write self.class.template.call( status, self.message )
  end


  DEFAULT_TEMPLATE = lambda do
    | status_code, xhtml_message |
    status_code = status_code.to_i
    xhtml_message = xhtml_message.to_s
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' +
    '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>HTTP/1.1 ' +
    status_code.to_s + ' ' + HTTP_STATUS_CODES[status_code] +
    '</title></head><body><h1>HTTP/1.1 ' +
    status_code.to_s + ' ' + HTTP_STATUS_CODES[status_code] +
    '</h1>' + xhtml_message + '</body></html>'
  end


  # The passed block must accept two arguments:
  # 1. *int* a status code
  # 2. *string* an xhtml fragment
  # and return a string
  def self.template(&block)
    @template ||= block || DEFAULT_TEMPLATE
  end


end


# Rack middleware, inspired by Rack::RelativeRedirect. Differences:
# - uses Rack::Utils::base_uri for creating absolute URIs.
# - the +Location:+ header, if present, is always rectified, independent of the
#   HTTP status code.
class RelativeLocation


  # Initialize a new RelativeRedirect object with the given arguments.  Arguments:
  # * app : The next middleware in the chain.  This is always called.
  # * &block : If provided, it is called with the environment and the response
  #   from the next middleware. It should return a string representing the scheme
  #   and server name (such as 'http://example.org').
  def initialize(app)
    @app = app
  end


  # Call the next middleware with the environment.  If the request was a
  # redirect (response status 301, 302, or 303), and the location header does
  # not start with an http or https url scheme, call the block provided by new
  # and use that to make the Location header an absolute url.  If the Location
  # does not start with a slash, make location relative to the path requested.
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


# Rack compliant server class for implementing RESTful web services.
class Server


  attr_accessor :resource_factory


=begin rdoc
Prototype constructor.
[resource_factory]
  An object responding to thread safe method #[].
  This method will be called with a path string, and must return a ReST::Resource.
=end
  def initialize(resource_factory = nil)
    super()
    @resource_factory = resource_factory
  end


=begin rdoc
  As required by the Rack specification. For thread safety, this method clones
  +self+, which handles the request in #call!.
=end
  def call(p_env)
    dup.call! p_env
  end


  def call!(p_env)
    request  = ReST::Request.new( p_env )
    response = Rack::Response.new
    Thread.current[:djinn_request] = request
    begin
      raise HTTPStatus, 'NOT_FOUND' \
        unless resource = self.resource_factory[request.path]
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
        response['Content-Length'] = 0
      end
    ensure
      Thread.current[:djinn_request] = nil
    end
    unless resource.path == request.path
      response.header['Content-Location'] = request.base_url + resource.path
    end
    # According to RFC2616 sections 10.2.2:
    if  201 == response.status &&
        ( location = response['Location'] ) &&
        ( new_resource = self.resource_factory[location] )
      new_resource.set_default_headers response
    # According to RFC2616 section 10.3.5:
    elsif 304 == response.status
      new_resource.set_default_headers response
    end
    response.finish
  end


end # class Server


end # module ReST

=begin
 BasicObject
  Exception
    IRB::Abort
    NoMemoryError
    ScriptError
      LoadError
        Gem::LoadError
      NotImplementedError
      SyntaxError
    SecurityError
    SignalException
      Interrupt
    StandardError
      ArgumentError
      EncodingError
        Encoding::CompatibilityError
        Encoding::ConverterNotFoundError
        Encoding::InvalidByteSequenceError
        Encoding::UndefinedConversionError
      Exception2MessageMapper::ErrNotRegisteredException
      FiberError
      IOError
        EOFError
      IRB::CantChangeBinding
      IRB::CantReturnToNormalMode
      IRB::CantShiftToMultiIrbMode
      IRB::IllegalParameter
      IRB::IrbAlreadyDead
      IRB::IrbSwitchedToCurrentThread
      IRB::NoSuchJob
      IRB::NotImplementedError
      IRB::Notifier::ErrUndefinedNotifier
      IRB::Notifier::ErrUnrecognizedLevel
      IRB::SLex::ErrNodeAlreadyExists
      IRB::SLex::ErrNodeNothing
      IRB::UndefinedPromptMode
      IRB::UnrecognizedSwitch
      IndexError
        KeyError
        StopIteration
      LocalJumpError
      Math::DomainError
      NameError
        NoMethodError
      RangeError
        FloatDomainError
      RegexpError
      RubyLex::AlreadyDefinedToken
      RubyLex::SyntaxError
      RubyLex::TerminateLineInput
      RubyLex::TkReading2TokenDuplicateError
      RubyLex::TkReading2TokenNoKey
      RubyLex::TkSymbol2TokenNoKey
      RuntimeError
        Gem::Exception
          Gem::CommandLineError
          Gem::DependencyError
          Gem::DependencyRemovalException
          Gem::DocumentError
          Gem::EndOfYAMLException
          Gem::FilePermissionError
          Gem::FormatException
          Gem::GemNotFoundException
          Gem::GemNotInHomeException
          Gem::InstallError
          Gem::InvalidSpecificationException
          Gem::OperationNotSupportedError
          Gem::RemoteError
          Gem::RemoteInstallationCancelled
          Gem::RemoteInstallationSkipped
          Gem::RemoteSourceException
          Gem::VerificationError
      SystemCallError
      ThreadError
      TypeError
      ZeroDivisionError
    SystemExit
      Gem::SystemExitException
    SystemStackError
    fatal
=end