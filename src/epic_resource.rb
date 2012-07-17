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

require 'rackful'

module EPIC


# Base class of all resources in this web service.
class Resource

  include Rackful::Resource


  GLOBAL_LOCK_MUTEX = Mutex.new
  GLOBAL_LOCK_HASH = {}


  def lock unlock = false
    self.class.lock self.path, unlock
  end


  def unlock
    self.lock true
  end


  def self.lock path, unlock
    GLOBAL_LOCK_MUTEX.synchronize do
      if unlock
        GLOBAL_LOCK_HASH.delete path
      elsif GLOBAL_LOCK_HASH[path]
        raise HTTPStatus, 'SERVICE_UNAVAILABLE Another client is modifying the resource.'
      else
        GLOBAL_LOCK_HASH[path] = true
      end
    end
  end


end


# Base class for all serializers. 
class Serializer

  include Enumerable

  attr_reader :resource, :request

  def initialize p_resource, p_request
    @resource, @request = p_resource, p_request
  end

end # class Serializer


class Serializer::TXT < Serializer; end

class Serializer::BIN < Serializer; end

class Serializer::JSON < Serializer; end

class Serializer::XHTML < Serializer

  def each &block
    yield header + '<div id="epic_content">'
    each_nested &block
    yield '</div>' + footer
  end

  def htmlify path
    base = self.request.path.slashify
    if base = path[0, base.size]
      path[ base.size .. -1 ]
    else
      path.dup
    end
  end

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
    retval =
'<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<link rel="stylesheet" href="/inc/bootstrap/css/bootstrap.min.css"/>
<link rel="stylesheet" href="/inc/bootstrap/css/bootstrap-responsive.min.css"/>'
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
    '<p align="right"><em>Developed for <a href="http://www.catchplus.nl/">CATCH+</a><br/>by <a href="http://www.sara.nl/">SARA</a></em></p></body></html>'
  end # footer

  def serialize p
    if p.kind_of?( Hash )
      '<table class="epic_object table table-striped table-bordered table-condensed">' +
      p.collect {
        |key, value|
        '<tr><th>' + key.to_s.split('_').collect{
          |word|
          word[0..0].upcase + word[1..-1]
        }.join(' ').escape_html +
        '</th><td class="epic_' + key.to_s.escape_html + '">' + self.serialize( value ) + "</td></tr>\n"
      }.join + '</table>'
    elsif p.kind_of?( Enumerable )
      begin
        raise 'Hash expected' unless p.first.kind_of?( Hash )
        keys = p.first.keys
        p.each {
          |value|
          raise 'Unexpected keys' unless value.keys == keys
        }
        '<table class="epic_objects table table-striped table-bordered table-condensed"><thead><tr>' +
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
            self.serialize(value) + "</td>\n"
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
