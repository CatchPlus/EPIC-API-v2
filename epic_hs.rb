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


require 'java'
require 'hsj/handle.jar'
require 'hsj/cnriutil.jar'


# The namespace for everything related to the EPIC Web Service.
module EPIC

module HS

  def self.hdllib; Java.NetHandleHdllib; end

  PERMS_BY_S = {
    :add_handle    => 0,
    :delete_handle => 1,
    :add_NA        => 2,
    :delete_NA     => 3,
    :modify_value  => 4,
    :remove_value  => 5,
    :add_value     => 6,
    :read_value    => 7,
    :modify_admin  => 8,
    :remove_admin  => 9,
    :add_admin     => 10,
    :list_handles  => 11
  }
  PERMS_BY_I = PERMS_BY_S.invert

  AUTHINFO = {}
  MUTEX = Mutex.new
  EMPTY_HANDLE_VALUE = hdllib.HandleValue.new

  def self.unpack_HS_ADMIN data
    adminRecord = hdllib.AdminRecord.new
    hdllib.Encoder.decodeAdminRecord(
      data.to_java_bytes, 0, adminRecord
    )
    perms = adminRecord.perms.to_a
    {
      :adminId => String.from_java_bytes( adminRecord.adminId ),
      :adminIdIndex => adminRecord.adminIdIndex,
      :perms => Hash[
        perms.each_index.collect {
          |i|
          [ PERMS_BY_I[i], perms[i] ] 
        }
      ]
    }
  end

  def self.pack_HS_ADMIN data
    raise Djinn::HTTPStatus, '500 Missing one or more required values' if
      ! data[:adminId] ||
      ! data[:adminIdIndex] ||
      ! data[:perms]
    adminRecord = hdllib.AdminRecord.new
    adminRecord.adminId = data[:adminId].to_s.to_java_bytes
    adminRecord.adminIdIndex = data[:adminIdIndex].to_i
    adminRecord.perms = data[:perms].collect {
      |perm|
      !!perm
    }.to_java Java::boolean
    String.from_java_bytes(
      hdllib.Encoder.encodeAdminRecord( adminRecord )
    )
  end

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
    user_name = ::EPIC::Resource.user_name
    unless AUTHINFO[user_name]
      userInfo = EPIC::USERS[user_name]
      raise Djinn::HTTPStatus, '500' unless userInfo
      MUTEX.lock
      begin
        unless AUTHINFO[user_name]
          AUTHINFO[user_name] = hdllib.SecretKeyAuthenticationInfo.new(
            userInfo[:handle].to_java_bytes,
            userInfo[:index],
            userInfo[:secret].to_java_bytes
          )
        end
      ensure
        MUTEX.unlock
      end
    end
    AUTHINFO[user_name]
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

end # class CurrentUser


end # module EPIC
