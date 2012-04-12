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

require 'djinn_restserver.rb'

module EPIC


# Base class of all resources in this web service.
class Resource
  include Djinn::Resource
end


# Base class for all serializers. 
class Serializer

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

end # class Serializer


class Serializer::TXT < Serializer; end

class Serializer::JSON < Serializer; end

class Serializer::XHTML < Serializer

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
<head>
<link rel="stylesheet" href="/inc/bootstrap/bootstrap.min.css"/>'
# <script type="text/javascript" src="/inc/jquery-1.7.1.min.js"></script> 
# <script type="text/javascript" src="/inc/jquery-tablesorter.js"></script> 
# <script type="text/javascript">//<![CDATA[
# $(document).ready(
  # function() { $(".tablesorter").tablesorter(); } 
# );
# //]]></script>'
    unless '/' == request.path[-1, 1] # unless request.path ends with a slash
      retval << '<base href="' << request.path.slashify << '"/>'
    end
    unless '/' == request.path
      retval << '<link rel="contents" href="' << File::dirname(request.path).slashify << '"/>'
    end
    retval << '<title>Index of ' << request.path.unescape_path.escape_html <<
      '</title></head><body>' << breadcrumbs
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

end # class Serializer::XHTML


end # module EPIC
