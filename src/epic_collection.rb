# Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
      yield path.relative + @newline
    end
  end
end # class EPIC::TXT


# Abstract base class for all collection-style resources in this web service.
class Collection < Resource

  add_serializer TXT

  # @!method each()
  # @yield [Rackful::Path]
  # @abstract

  include Enumerable

  def recurse?
    depth = Rackful::Request.current.env['HTTP_DEPTH'] || (
      self.class.const_defined?( :DEFAULT_DEPTH ) ? DEFAULT_DEPTH.to_s : '0'
    )
    'infinity' == depth || self.requested? && '0' != depth
  end


  def to_rackful
    self.recurse? ? Recursive.new(self) : self
  end


  def xhtml_start
    '<h1>Contents</h1>'
  end


  def xhtml_help
    retval = <<EOS
<h2>Collections</h2>
<p>This resource is nothing but a <em>collection</em> of other resources.<br/>
Please note that its URL ends with a slash "/". This slash is <em>not</em> optional; it's required for every collection.</p>
<h3>Request headers</h3>
<dl class="dl-horizontal">
  <dt>Depth:</dt>
  <dd>This header MUST have value <code>0</code>, <code>1</code> or <code>infinity</code>.
    With <code>Depth: 0</code>, only links to child resources are shown.
    With <code>Depth: 1</code>, the child resources themselves are returned as well, as if
    they were requested with <code>Depth: 0</code>.
    With <code>Depth: infinity</code>, child resources and their child resources are returned,
    ad infinitum.
  </dd>
  <dt>Accept:</dt>
  <dd>Apart from the formats supported by all resources, collections can also
    be represented as plain text, by supplying the <code>Accept: text/plain</code> request header.
    The plain text representation doesn't support recursion using the <code>Depth:</code> header.</dd>
</dl>
<h3>Query parameters</h3>
Because collections can get very lange, they are rendered page by page.
By default, you'll only see the first page with at maximum 1000 results.
To modify this behaviour, use the following query parameters:
<dl class="dl-horizontal">
  <dt>limit</dt>
  <dd>the maximum number of items to return. The default is 1000. As a special
    case, if you specify <code>limit=0</code>, <em>all</em> items will be returned,
    without limit.
  </dd>
  <dt>page:</dt>
  <dd>the number of the page to return. I.e., if you specify <code>limit=100&amp;page=3</code>,
    items 201 through 300 will be returned.</dd>
</dl>
EOS
  retval + super
  end


  class Recursive

    include Enumerable

    def initialize resource
      @resource = resource
    end

    def each
      rf = Rackful::Request.current.resource_factory
      @resource.each do
        |path|
        yield path, rf[path]
      end
    end

    alias_method :each_pair, :each

  end # class Collection::Recursive

end # class Collection


class StaticCollection < Collection

  # @param [Path] path
  # @param [Enumerable<#to_s>] uris an array of URIs
  def initialize path, uris
    super path
    @uris = uris.collect { |uri| (path + uri.to_s).to_path }
  end

  def each &block; @uris.each( &block ); end

end # class StaticCollection


end # module EPIC
