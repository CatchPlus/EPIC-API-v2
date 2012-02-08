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
  
module Serializer
  
# Base class for all serializers. 
class Base
  
  include Enumerable
  
  attr_reader :resource, :request
  
  def initialize resource, request
    @resource = resource
    @request = request
  end
  
  def requested?
    self.resource.path.slashify == request.path.slashify
  end
  
  def recurse?
    depth = ( self.resource.class.constants.include? :DEFAULT_DEPTH ) ?
      self.resource.class::DEFAULT_DEPTH.to_s : '0'
    depth = request.env['HTTP_DEPTH'] || depth
    requested? && '0' != depth || 'infinity' == depth
  end

end # class Base

class TXT < Base; end

class JSON < Base; end

class BIN < Base; end

class XHTML < Base
  
  def breadcrumbs
    segments = request.path.split('/')
    segments.pop
    return '' if segments.empty?
    bc_path = ''
    '<ul class="breadcrumb">' + segments.collect do
      |segment|
      bc_path += segment + '/'
      '<li><a href="' + bc_path + '" rel="' + (
        segment.empty? && 'home' || 'contents'
      ) + '">' + (
        segment.empty? && 'home' || segment.unescape_path
      ) + '</a><span class="divider">/</span></li>'
    end.join + '</ul>'
  end # def breadcrumbs
    
  def header
    return '' if !requested? || request.xhr?
    retval =
'<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>'
    unless '/' == request.path[-1, 1]
      retval << '
<base href="' << request.path.slashify << '"/>'
    end
    retval << '
<link rel="stylesheet" href="/inc/bootstrap/bootstrap.min.css"/>
<script type="text/javascript" src="/inc/jquery-1.7.1.min.js"></script> 
<script type="text/javascript" src="/inc/jquery-tablesorter.js"></script> 
<script type="text/javascript">//<![CDATA[
$(document).ready(
  function() { $(".tablesorter").tablesorter(); } 
);
//]]></script>'
    unless '/' == request.path
      retval << '
<link rel="contents" href="' << File::dirname(request.path).slashify << '"/>'
    end
    retval << '
<title>Index of ' << request.path.unescape_path.escape_html << '</title>
</head><body>' << breadcrumbs
    retval
  end # header
  
  def footer
    if !requested? || request.xhr?
      ''
    else
      '<p align="right"><em>Developed for <a href="http://www.catchplus.nl/">CATCH+</a><br/>by <a href="http://www.sara.nl/">SARA</a></em></p></body></html>'
    end
  end # footer
  
  def serialize p
    case
    when p.kind_of?( Hash )
      '<table class="condensed-table bordered-table zebra-striped">' +
      p.collect {
        |key, value|
        '<tr><th>' + key.to_s.split('_').collect{
          |word|
          word[0..0].upcase + word[1..-1]
        }.join(' ').escape_html +
        '</th><td class="epic_' + key.to_s.escape_html + '">' + self.serialize( value ) + "</td></tr>\n"
      }.join + '</table>'
    when p.kind_of?( Enumerable )
      begin
        raise 'dah' unless p.first.kind_of?( Hash )
        keys = p.first.keys
        p.each {
          |value|
          raise 'dah' unless value.keys == keys
        }
        '<table class="tablesorter condensed-table bordered-table zebra-striped"><thead><tr>' +
        keys.collect {
          |column|
          '<th>' +
          column.to_s.split('_').collect{
            |word|
            word[0..0].upcase + word[1..-1]
          }.join(' ').escape_html +
          "</th>\n"
        }.join + '</tr></thead><tbody>' + p.collect {
          |h|
          '<tr>' + h.collect {
            |key, value|
            '<td class="epic_' + key.to_s.escape_html + '">' +
            item[column].to_s.escape_html + "</td>\n"
          }.join + '</tr>'
        }.join + "</tbody></table>"
      rescue
        '<ul class="unstyled">' + p.collect {
          |value|
          '<li>' + self.serialize(value) + "</li>\n"
        }.join + "</ul>\n"
      end
    else
      p.to_s.escape_html
    end
  end
  
end # class XHTML

end # module Serializer
  
  
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


class HandleValue::BIN < Serializer::BIN
  def each
    yield 'binary respresentation'
  end
end # class HandleValue::XHTML


class HandleValue::JSON < Serializer::JSON
  def each
    yield '"hello"'
  end
end # class HandleValue::TXT
  
end # module EPIC
