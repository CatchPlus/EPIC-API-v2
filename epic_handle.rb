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


def hdllib; Java.NetHandleHdllib; end


# The namespace for everything related to the EPIC Web Service.
module EPIC
  
  
module HS
  

AUTHINFO = {}
MUTEX = Mutex.new
  
  
def self.resolver
  unless @@resolver
    MUTEX.lock
    begin
      unless @@resolver
        @@resolver = hdllib.HandleResolver.new
        sessionSetupInfo = hdllib.SessionSetupInfo.new nil
        clientSessionTracker = hdllib.ClientSessionTracker.new sessionSetupInfo
        @@resolver.setSessionTracker clientSessionTracker
      end
    ensure
      MUTEX.unlock
    end
  end
end


def self.authenticationInfo
  userName = Thread.current[:request].env['REMOTE_USER']
  unless AUTHINFO[userName]
    userInfo = EPIC::USER[userName]
    raise Djinn::HTTPStatus, '500' unless userInfo
    MUTEX.lock
    begin
      unless AUTHINFO[userName]
        AUTHINFO[userName] = hdllib.SecretKeyAuthenticationInfo.new(
          userInfo[:handle].to_java_bytes,
          userInfo[:index],
          userInfo[:secret].to_java_bytes
        )
      end
    ensure
      MUTEX.unlock
    end
  end
  AUTHINFO[userName]
end
  

end # module HS


# :category: Deprecated
class CurrentUser
  
  @@resolvers = {}
  @@authInfo  = {}

  def self.resolver(p_handle = HANDLE, p_idx = IDX)
    id = "#{p_idx}:#{p_handle}"
    return @@resolvers[id] if @@resolvers[id]
     
    @@resolvers[id] = hdllib.HandleResolver.new
    sessionTracker  = hdllib.ClientSessionTracker.new
    @@authInfo[id]  = hdllib.PublicKeyAuthenticationInfo.new(
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
    sessionInfo = hdllib.SessionSetupInfo.new(@@authInfo[id])
    #sessionInfo.encrypted = true
    sessionTracker.setSessionSetupInfo(sessionInfo)
    @@resolvers[id].setSessionTracker(sessionTracker)
    @@resolvers[id]
  end
  
  def self.authInfo(p_handle = HANDLE, p_idx = IDX)
    id = "#{p_idx}:#{p_handle}"
    return @@authInfo[id]
  end
  
end # class Administrator


end # module EPIC
