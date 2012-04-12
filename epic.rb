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
# This is the source code documentation of the EPIC API version 2.
#
# The project is hosted at GitHub, as
# EPIC-API-v2[http://github.com/CatchPlus/EPIC-API-v2]

require 'config.rb'
require 'secrets/users.rb'

require 'epic_monkeypatches.rb'
require 'epic_activerecords.rb'
require 'epic_resources.rb'

require 'singleton'


# The namespace for everything related to the EPIC Web Service.
module EPIC
  
  
# Like every Singleton, this class must be thread safe!
class ResourceFactory
  
  include Singleton
  
  def [] path
    case path.to_s.unslashify
    when ''
      StaticCollection.new '/'
    when '/handles', '/profiles', '/templates'
      NAs.new path.slashify
    when %r{\A/handles/\d+\z}
      Handles.new path.slashify
    when %r{\A/handles/\d+/[^/]+\z}
      Handle.new path #.unslashify
    else
      nil
    end
  end
  
end # class ResourceFactory


end # module EPIC
