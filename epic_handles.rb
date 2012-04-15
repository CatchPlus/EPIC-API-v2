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

require './epic_collection.rb'
require './epic_sequel.rb'

module EPIC

class Handles < Collection

  def prefix
    @epic_handles_prefix ||= File::basename(path.unslashify).unescape_path
  end

=begin rdoc
TODO: better implementation (server-side data retention) for streaming responses.
=end
  def each &block
    start_position = self.prefix.size + 1
    # ActiveHandleValue.select([:handle, :id]).
      # where('`handle` LIKE ?', self.prefix + '/%').
      # group_by(:handle).
      # find_each do |ahv|
        # yield ahv.handle[start_position .. -1]
      # end
    # if self.recurse?
      # DB.instance.all_handles.collect {
        # |handle|
        # handle[start_position .. -1].escape_path
      # }.each &block
    # else
    DB.instance.all_handles.each do
      |handle|
      yield handle[start_position .. -1].escape_path
    end
    # end
  end

end # class Handles

end # module EPIC
