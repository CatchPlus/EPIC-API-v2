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
# =DjinnIT RESTServer
# This module implements a Rack compliant server class for implementing
# RESTful web services.

# Used by HTTPStatus
require 'rexml/document'
require 'rack'
require 'thread'


module Djinn


class Request < Rack::Request


  def self.current
    Thread.current[:djinn_request]
  end


=begin rdoc
Returns a Hash of <tt>media type => quality</tt> pairs, with acceptable media types
for the response. This information is also stored in environment variable
+djinn.accept+ for caching.

If no acceptable media types are provided, an empty Hash is returned.
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
Returns the best media type for the response body, given the client's +Accept:+
header(s) and the available representations in the server.

[content_types]
  Hash of <tt>media type => quality</tt> pairs, indicating what kind of media types
  can be provided, and what their relative qualities are.
[fail]
  Boolean, indicating if this method should throw an HTTPStatus object with
  status +406 Not Acceptable+ if there's no match.
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
      raise HTTPStatus, '406' if require_match
      nil
    else
      matches.sort_by(&:last).last[0]
    end
  end


  def truthy? parameter
    value = self.GET[parameter] || ''
    %r{\A(1|t(rue)?|y(es)?|on)\z}i === value
  end


  def falsy? parameter
    value = self.GET[parameter] || ''
    %r{\A(0|f(alse)?|n(o)?|off)\z}i === value
  end


  def if_match etag, none = false
    header = @env["HTTP_IF_#{ none ? 'NONE_' : '' }MATCH"]
    return true unless header
    envkey = "djinn.if_#{ none ? 'none_' : '' }match"
    @env[envkey] ||=
      if %r{\A\s*\*\s*\z} === header
        ['*']
      elsif %r{\A(\s*(W/)?"([^"\\]|\\.)*"\s*,)+\z} === ( header + ',' )
        header.scan %r{(?:W/)?"(?:[^"\\]|\\.)*"}
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


  def if_none_match etag
    self.if_match etag, true
  end


  def if_modified_since time, unmodified = false
    header = @env["HTTP_IF_#{ unmodified ? 'UN' : '' }MODIFIED_SINCE"]
    return true unless header
    header = Time.httpdate( header )
    modified = time > header
    modified ^ unmodified
  end


  def if_unmodified_since time
    self.if_modified_since time, true
  end


end # class Request


=begin rdoc
Mixin for resource objects.

Classes that include this module may implement a method +content_types+
for content negotiation. This method must return a hash of
<tt>mime-type => quality</tt> pairs. If such a method is provided, then the
the app will determine the best content type for the response body on +GET+
requests, and set this in
  response.header['Content-Type']
when calling
  do_GET( request, response )
=end
module Resource

  include Rack::Utils
  def path; @djinn_resource_path; end

  def initialize path
    @djinn_resource_path = path
  end


=begin rdoc
Flags if the resource _exists_. For example, a client can +PUT+ to a URL that
doesn't refer to a resource yet. In that case, an _empty_ resource can be
provided to handle the +PUT+ request. +HEAD+ and +GET+ requests will still
yield a <tt>404 Not Found</tt>.
=end
  def empty?
    false
  end


  def http_methods
    unless @djinn_resource_http_methods
      @djinn_resource_http_methods = []
      self.public_methods.each do
        |public_method|
        if ( match = /\Ado_([A-Z]+)\z/.match( public_method ) )
          @djinn_resource_http_methods << match[1]
        end
      end
      @djinn_resource_http_methods.delete 'HEAD' \
        unless @djinn_resource_http_methods.include? 'GET'
    end
    @djinn_resource_http_methods
  end


  def http_HEAD request, response
    raise Djinn::HTTPStatus, 'NOT_FOUND' if self.empty?
    self.do_HEAD request, response
    self.set_default_headers response
  end


  def http_GET request, response
    raise Djinn::HTTPStatus, 'NOT_FOUND' if self.empty?
    raise Djinn::HTTPStatus, 'METHOD_NOT_ALLOWED ' +  self.http_methods.join( ' ' ) \
      unless self.respond_to? :do_GET
    self.do_GET request, response
    self.set_default_headers response
  end


  # @private
  def set_default_headers response
    if ! response.include?( 'ETag' ) &&
       ( etag = self.header_etag )
      response['ETag'] = etag
    end
    if ! response.include?( 'Last-Modified' ) &&
       ( last_modified = self.header_last_modified )
      response['Last-Modified'] = last_modified.httpdate
    end
  end


=begin rdoc
Handles a HEAD request.

If a subclass implements method +content_types+, then the +Content-Type+ header
will be set in the response object passed to +do_GET+.
=end
  def do_HEAD request, response
    raise Djinn::HTTPStatus, 'METHOD_NOT_ALLOWED ' +  self.http_methods.join( ' ' ) \
      unless self.respond_to? :do_GET
    self.do_GET request, response
    response.body = []
  end


=begin rdoc
Handles an OPTIONS request.

An +Allow:+ header is created, listing all implemented HTTP methods
for this resource.

By default, an *HTTP/1.1 204 No Content* is returned (without an entity
body). Users may override what's returned by implementing a method
#user_OPTIONS which takes two parameters:
1. a Rack::Request object
2. a Rack::Response object, to be modified at will.
=end
  def do_OPTIONS request, response
    raise Djinn::HTTPStatus, 'NOT_FOUND' if self.empty?
    response.status = status_code :no_content
    response.header['Allow'] = self.http_methods.join ', '
  end


  def header_etag; nil; end


  def header_last_modified; Time.now; end


  # Raises 412 Precondition Failed on failure to match
  def assert_if_headers request
    if self.empty? && (
         request.env.key?('HTTP_IF_MATCH')
         ! request.if_unmodified_since( Time.now + 1 )
       ) or
       ! self.empty? && (
         ! request.if_none_match( self.header_etag ) ||
         ! request.if_match( self.header_etag ) ||
         ! request.if_unmodified_since( self.header_last_modified )
       )
      raise HTTPStatus, 'PRECONDITION_FAILED'
    end
    if self.empty? && ! request.if_modified_since( 0 )
      raise HTTPStatus, 'NOT_FOUND'
    end
    if ! self.empty? &&
       ! request.if_modified_since( self.header_last_modified )
      raise HTTPStatus, 'NOT_MODIFIED'
    end
  end


end


# This class has a dual nature. It inherits from RuntimeError, so that it may
# be used together with #raise.
class HTTPStatus < RuntimeError


  include Rack::Utils


  attr_reader :response


  # The general format of +message+ is: +<status> [ <space> <message> ]+
  def initialize( message )
    @response = Rack::Response.new
    matches = %r{\A(\S+)\s*(.*)\z}.match(message.to_s)
    #raise ArgumentError, "Unexpected message format: '#{message}'"
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


# The server class.
class RESTServer


  attr_accessor :resource_factory

=begin rdoc
Prototype constructor.
[resource_factory]
  An object responding to thread safe method #[].
  This method will be called with a path string, and must return a Djinn::Resource.
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
    request  = Djinn::Request.new( p_env )
    response = Rack::Response.new
    request.env['djinn.response'] = response
    Thread.current[ :djinn_request ] = request
    begin
      raise HTTPStatus, '404' unless resource = self.resource_factory[request.path]
      # Why are we looking for both "http_*" and "do_*" methods?
      # Why not just one of these?
      # if resource.respond_to? :"http_#{request.request_method}"
        # resource.__send__( :"http_#{request.request_method}", request, response )
      # els
      resource.assert_if_headers request
      if resource.respond_to? :"http_#{request.request_method}"
        resource.__send__( :"http_#{request.request_method}", request, response )
      elsif resource.respond_to? :"do_#{request.request_method}"
        resource.__send__( :"do_#{request.request_method}", request, response )
      else
        raise HTTPStatus, '405 ' + resource.http_methods.join( ' ' )
      end
      unless resource.path == request.path
        response.header['Content-Location'] = request.base_url + resource.path
      end
      #[200, {'Content-Type'=>'text/plain'},[response.header['Content-Type']]]
      response.finish
    rescue HTTPStatus => s
      #DONE: comment out the following line:
      #raise
      raise if 500 == s.response.status
      s.response.body = [] if request.head?
      s.response.finish
    ensure
      Thread.current[ :djinn_request ] = nil
    end
  end


end # class RESTServer


end # module Djinn

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