#--
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
#++

require './epic_resource.rb'

module EPIC


# Abstract base class for all collection-style resources in this web service.
class Collection < Resource

  include Enumerable

  CONTENT_TYPES = {
    'application/xhtml+xml; charset=UTF-8' => 1,
    'text/html; charset=UTF-8' => 1,
    'text/xml; charset=UTF-8' => 1,
    'application/xml; charset=UTF-8' => 1,
    'application/json; charset=UTF-8' => 0.5,
    'application/x-json; charset=UTF-8' => 0.5,
    'text/plain; charset=UTF-8' => 0.1
  }

  def do_GET request, response
    bct = request.best_content_type CONTENT_TYPES
    response.header['Content-Type'] = bct
    response.body = case bct.split( ';' ).first
    when 'text/plain'
      TXT.new self, request
    when 'application/json', 'application/x-json'
      JSON.new self, request
    else
      XHTML.new self, request
    end
  end

  def requested?
    path.slashify == globals[:request].path.slashify
  end

  def recurse?
    depth = ( self.class.constants.include? :DEFAULT_DEPTH ) ?
      DEFAULT_DEPTH.to_s : '0'
    depth = globals[:request].env['HTTP_DEPTH'] || depth
    requested? && '0' != depth || 'infinity' == depth
  end

end # class Collection


class Collection::XHTML < Serializer::XHTML

  def each_nested &block # :yields: strings
    recurse = self.resource.recurse?
    html = '
<table class="epic_collection table table-striped table-bordered table-condensed">
<thead><tr><th class="epic_uri">URI</th>'
    html << '<th class="epic_resource">Resource</th>' if recurse
    html << '</tr></thead><tbody>'
    yield html
    self.resource.each do |uri|
      uri = uri.to_s
      html = '<tr class="epic_resource"><td class="epic_uri"><a href="' +
        uri + '">' +
        uri.split('?', 2).first.unescape_path.escape_html +
        "</a></td>\n"
      if recurse
        html << '<td class="epic_resource">'
        yield html
        child = ResourceFactory.instance[ self.resource.path + uri.split('?', 2).first ]
        child.class::XHTML.new(child, request).each_nested(&block) if child
        html = '</td>'
      end
      html << '</tr>'
      yield html
    end
    yield '</tbody></table>'
  end

=begin
  def every_bak
    columns = nil
    self.resource.each do |item|
      # First time around, we're gonna see what columns we need.
      unless columns
        recurse = self.resource.recurse?
        # recurse = (
          # self.resource.recurse? &&
          # ( child = ResourceFactory.instance[self.resource.path.slashify + item[:uri].to_s] ) &&
          # ! child.empty? && child.kind_of?(Collection)
        # )
        columns = item.keys
        columns.delete :uri
        columns.unshift :uri
        html = '<table class="epic_collection condensed-table bordered-table zebra-striped">
<thead><tr>'
        html << columns.collect { |column|
          '<th>' + column.to_s.split('_').collect{
            |word|
            word[0..0].upcase + word[1..-1]
          }.join(' ').escape_html + '</th>'
        }.join
        html << '<th>Contents</th>' if recurse
        html << '</tr></thead><tbody>'
        yield html
      end
      html = '<tr class="epic_resource">'
      columns.each do |column|
        if :uri == column
          html << '<td class="epic_uri"><a href="' +
            item[:uri].to_s + '">' +
            item[:uri].to_s.unescape_path.escape_html + "</a></td>\n"
        else
          html << '<td class="epic_' + column.to_s + '">' +
            self.serialize(item[column]) + "</td>\n"
        end
      end
      if recurse
        child = ResourceFactory.instance[self.resource.path.slashify + item[:uri].to_s]
        if child
          yield '<td class="epic_contents">' +
            Collection::XHTML.new(child, request).join +
            '</td>'
        else
          yield '<td></td>'
        end
      end
      yield '</tr>'
    end
    yield '</tbody></table>'
  end
=end

end # class Collection::XHTML


class Collection::JSON < Serializer::JSON
  def each
    yield '{'
    first = true
    self.resource.each do
      |item|
      uri = item[:uri]
      #if 0 == uri.index(self.resource.path)
      #  uri = uri[Range.new(self.resource.path.length, -1)]
      #end
      item = item.dup
      item.delete :uri
      yield( (first && '' || ',') + uri.to_json + ':' + ::JSON.generate(item) )
      first = false
    end
    yield '}'
  end
end # class Collection::JSON


class Collection::TXT < Serializer::TXT
  def each
    self.resource.each { |item| yield( item[:uri] + "\r\n" ) }
  end
end # class Collection::TXT


class StaticCollection < Collection

  def initialize path, uris
    super path
    @uris = uris
  end

  def each &block; @uris.each &block; end

  #def recurse?; false; end

end # class StaticCollection


end # module EPIC
