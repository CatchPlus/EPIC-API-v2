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
   
module EPIC
  
  
# Abstract base class for all collection-style resources in this web service.
class Collection < Resource
  
  include Enumerable
  
  def content_types
    {
      'application/xhtml+xml; charset=UTF-8' => 1,
      'text/html; charset=UTF-8' => 1,
      'text/xml; charset=UTF-8' => 1,
      'application/xml; charset=UTF-8' => 1,
      'application/json; charset=UTF-8' => 0.5,
      'application/x-json; charset=UTF-8' => 0.5,
      'text/plain; charset=UTF-8' => 0.1
    }
  end
  
  def do_GET request, response
    response.body = case response.header['Content-Type'].to_s.split( ';' ).first.strip
    when 'text/plain'
      TXT.new self, request
    when 'application/json', 'application/x-json'
      JSON.new self, request
    else
      XHTML.new self, request
    end
  end
  
end # class Collection


class Collection::XHTML < Serializer::XHTML
  def each
    yield header
    columns = nil
    self.resource.each do |item|
      unless columns
        recurse = (
          self.recurse? &&
          ( child = ResourceFactory.instance[self.resource.path.slashify + item[:uri].to_s] ) &&
          ! child.empty? && child.kind_of?(Collection)
        )
        columns = item.keys
        columns.delete :uri
        columns.unshift(:name) if item[:uri] && ! item[:name]
        yield '
<table class="tablesorter condensed-table bordered-table zebra-striped">
<thead><tr>'
        yield( columns.collect { |column|
          '<th>' + column.to_s.split('_').collect{
            |word|
            word[0..0].upcase + word[1..-1]
          }.join(' ').escape_html + '</th>'
        }.join )
        yield '<th>Contents</th>' if recurse
        yield '</tr></thead><tbody>'
      end
      item[:name] = item[:uri].unslashify.unescape_path if
        item[:uri] && ! item[:name]
      yield '<tr class="epic_resource">'
      columns.each do |column|
        if :name == column && item[:uri]
          yield '<td class="epic_name"><a href="' +
            item[:uri].to_s + '">' +
            item[:name].to_s.escape_html + "</a></td>\n"
        else
          yield '<td class="epic_' + column.to_s + '">' +
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
    yield footer
  end
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
  
  def initialize path
    super path
    case path
    when '/'
      @collection = [
        { :uri => 'handles/',   :description => 'all handles, indexed by prefix' },
        { :uri => 'profiles/',  :description => 'all profiles, indexed by prefix' },
        { :uri => 'templates/', :description => 'all templates, indexed by prefix' },
      ]
    else
      raise Djinn::HTTPStatus,
        "500 No static collection at #{path.unescape_path}"
    end
  end
  
  def each &block
    @collection.each &block
  end
  
end # class StaticCollection


end # module EPIC
