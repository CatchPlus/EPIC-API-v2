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


class Template < Resource


  attr_reader :filename


  CONTENT_TYPES = {
    'application/xhtml+xml; charset=UTF-8' => 1,
    'text/html; charset=UTF-8' => 1,
    'text/xml; charset=UTF-8' => 1,
    'application/xml; charset=UTF-8' => 1
  }


  def initialize path, register = false
    super path
    @filename = "./public#{self.path.unescape_path}"
    # TODO IMPLEMENT
  end


  # @see Rackful::Resource#do_Method
  def do_GET request, response
    bct = request.best_content_type CONTENT_TYPES
    response.header['Content-Type'] = bct
    response.body = XHTML.new self, request
  end


  def empty?
    ! File.exist? self.filename
  end


  # @return [Time]
  # @see Rackful::Resource#last_modified
  def last_modified
    [
      File.mtime( self.filename ),
      false
    ]
  end


end # class Profile


class Template::XHTML < Serializer::XHTML


  def each_nested # :yields: strings
    yield ''
  end


end # class Collection::XHTML


end # module EPIC
