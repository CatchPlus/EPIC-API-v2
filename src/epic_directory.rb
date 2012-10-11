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

require 'epic_collection.rb'

module EPIC

# @deprecated This class doesn't seem to be used anymore.
class Directory < Collection

  def each
    dirname = "./public#{self.path.unescape}"
    Dir.open dirname do
      |dir|
      dir.each do
        |filename|
        filepath = dirname + filename
        yield Rackful::Path.new( self.path + escape_path(filename) ) \
          if File::file? filepath
      end
    end
  end

end # class NAs

end # module EPIC
