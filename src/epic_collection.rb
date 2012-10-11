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

require 'epic_resource.rb'

module EPIC


class TXT < Rackful::Serializer
  CONTENT_TYPES = [
    'text/plain; charset=US-ASCII',
    'text/csv; charset=US-ASCII',
  ]
  def initialize *args
    super(*args)
    @newline = ( 'text/csv; charset=US-ASCII' == self.content_type ) ?
      "\r\n" : "\n"
  end
  def each
    self.resource.each do
      |path|
      yield path.to_s + @newline
    end
  end
end # class EPIC::TXT


# Abstract base class for all collection-style resources in this web service.
class Collection < Resource

  add_serializer TXT

=begin
@!method each()
@yield [Rackful::Path]
@abstract
=end

  include Enumerable

  def recurse?
    depth = self.class.const_defined?( :DEFAULT_DEPTH ) ?
      DEFAULT_DEPTH.to_s : '0'
    depth = Rackful::Request.current.env['HTTP_DEPTH'] || depth
    self.requested? && '0' != depth || 'infinity' == depth
  end

  def to_rackful
    self.recurse? ? Recursive.new(self) : self
  end

  def xhtml
    '<h1>Contents:</h1>'
  end

  class Recursive

    include Enumerable

    def initialize resource
      @resource = resource
    end

    def each_pair
      rf = Rackful::Request.current.resource_factory
      @resource.each do
        |path|
        yield path, rf[path]
      end
    end

    def each &block
      @resource.each &block
    end

  end # class Collection::Recursive

end # class Collection


class StaticCollection < Collection

  # @param [Path] path
  # @param [Enumerable<#to_s>] uris an array of URIs
  def initialize path, uris
    super path
    @uris = uris.collect { |uri| (path + uri.to_s).to_path }
  end

  def each &block; @uris.each &block; end

end # class StaticCollection


end # module EPIC
