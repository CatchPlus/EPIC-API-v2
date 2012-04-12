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

require 'epic_collection.rb'
require 'epic_activerecords.rb'

module EPIC

class Handles < Collection

  def prefix
    @prefix ||= File::basename(path.unslashify).unescape_path
  end

  def each
    ActiveHandleValue.select(:handle).uniq.
      where('`handle` LIKE ?', self.prefix + '/%').
      find_each do |ahv|
        suffix = %r{\A[^/]+/(.*)}.match(ahv.handle)[1]
        yield( { :uri => suffix.escape_path, :name => "#{prefix}/#{suffix}" } )
      end
  end

end # class Handles

end # module EPIC
