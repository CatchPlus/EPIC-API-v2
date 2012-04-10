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

require 'epic_monkeypatches.rb'
require 'epic_activerecords.rb'
require 'epic_resources.rb'
require 'epic_serializers.rb'
require 'epic_middlewares.rb'
require 'singleton'


def hdllib; Java.NetHandleHdllib; end


# The namespace for everything related to the EPIC Web Service.
module EPIC
  
  
class CurrentUser
  
  HANDLE = '0.NA/10916'
  IDX = 300

  @resolvers = {}
  @authInfo = {}

  def self.resolver(p_handle = HANDLE, p_idx = IDX)
    id = "#{p_idx}:#{p_handle}"
    return @resolvers[id] if @resolvers[id]
     
    @resolvers[id] = hdllib.HandleResolver.new
    sessionTracker = hdllib.ClientSessionTracker.new
    @authInfo[id] = hdllib.PublicKeyAuthenticationInfo.new(
      p_handle.to_java_bytes,
      p_idx,
      hdllib.Util.getPrivateKeyFromBytes(
        hdllib.Util.decrypt(
          hdllib.Util.getBytesFromFile('secrets/' + id.gsub(/\W+/, '_')),
          nil
        ),
        0
      )
    )
    sessionInfo = hdllib.SessionSetupInfo.new(@authInfo[id])
    #sessionInfo.encrypted = true
    sessionTracker.setSessionSetupInfo(sessionInfo)
    @resolvers[id].setSessionTracker(sessionTracker)
    @resolvers[id]
  end
  
  def self.authInfo(p_handle = HANDLE, p_idx = IDX)
    id = "#{p_idx}:#{p_handle}"
    return @authInfo[id]
  end
  
end # class CurrentUser


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
