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


class Profile < Resource


  attr_reader :filename


  def initialize path, register = false
    super path
    @filename = "./public#{self.path.unescape}"
    # TODO IMPLEMENT
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


  def to_rackful; nil; end


end # class Profile


end # module EPIC
