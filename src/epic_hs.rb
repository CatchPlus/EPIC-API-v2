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


  HDLLIB = Java::NetHandleHdllib

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
  EMPTY_HANDLE_VALUE = HDLLIB::HandleValue.new


  def self.unpack_HS_ADMIN data
    adminRecord = HDLLIB::AdminRecord.new
    HDLLIB::Encoder.decodeAdminRecord(
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
    raise 'Missing one or more required values' \
      if ! data.kind_of?( Hash ) ||
         ! data[:adminId] ||
         ! data[:adminIdIndex] ||
         ! data[:perms] ||
         ! data[:perms].kind_of?( Hash ) ||
         ! data[:perms].keys.all? { |k| PERMS_BY_S[k] }
    adminRecord = HDLLIB::AdminRecord.new
    adminRecord.adminId = data[:adminId].to_s.to_java_bytes
    adminRecord.adminIdIndex = data[:adminIdIndex].to_i
    perms = Hash[
      data[:perms].collect do
        |key, value|
        key = key.to_sym
        [ key, value ]
      end
    ]
    adminRecord.perms = PERMS_BY_I.values.collect do
      |perm|
      !!perms[perm]
    end.to_java Java::boolean
    String.from_java_bytes(
      HDLLIB::Encoder.encodeAdminRecord( adminRecord )
    )
  end


  def self.unpack_HS_VLIST data
    vlist = HDLLIB::Encoder.decodeValueReferenceList(
      data.to_java_bytes, 0
    )
    vlist.to_a.collect do
      |ref|
      { :idx => ref.index, :handle => String.from_java_bytes( ref.handle ) }
    end
  end


  def self.pack_HS_VLIST data
    raise 'Bad HS_VLIST data.' \
      if ! data.kind_of?( Array ) ||
         ! data.all? {
           |ref|
           ref.kind_of?(Hash) &&
           ref[:idx] &&
           ref[:idx].respond_to?(:to_i) &&
           ref[:handle] &&
           ref[:handle].respond_to?(:to_s)
         }
    data = data.collect do
      |ref|
      HS::HDLLIB::ValueReference.new(
        ref[:handle].to_s.to_java_bytes,
        ref[:idx].to_i
      )
    end.to_java HS::HDLLIB::ValueReference
    String.from_java_bytes(
      HDLLIB::Encoder.encodeValueReferenceList( data )
    )
  end


  # HandleResolver should be thread safe, so there's only one of it.
  def self.resolver
    unless class_variable_defined? :@@resolver
      MUTEX.synchronize do
        unless class_variable_defined? :@@resolver
          @@resolver = HDLLIB::HandleResolver.new
          sessionSetupInfo = HDLLIB::SessionSetupInfo.new nil
          clientSessionTracker = HDLLIB::ClientSessionTracker.new sessionSetupInfo
          @@resolver.setSessionTracker clientSessionTracker
        end
      end
    end
    @@resolver
  end


  def self.authenticationInfo user_name
    unless AUTHINFO[user_name]
      userInfo = EPIC::USERS[user_name]
      raise "No user info found for user '#{user_name}'" unless userInfo
      MUTEX.synchronize do
        AUTHINFO[user_name] ||= HDLLIB::SecretKeyAuthenticationInfo.new(
          userInfo[:handle].to_java_bytes,
          userInfo[:index],
          userInfo[:secret].to_java_bytes,
          true
        )
      end
    end
    AUTHINFO[user_name]
  end


  def self.delete handle, user_name
    request = HDLLIB::DeleteHandleRequest.new(
      handle.to_java_bytes,
      authenticationInfo( user_name )
    )
    response = resolver.processRequest( request )
    if response.kind_of? HDLLIB::ErrorResponse
      case response.responseCode
      when HDLLIB::ErrorResponse::RC_INSUFFICIENT_PERMISSIONS
        raise ReST::HTTPStatus, 'FORBIDDEN'
      when HDLLIB::ErrorResponse::RC_HANDLE_NOT_FOUND
        raise ReST::HTTPStatus, 'NOT_FOUND'
      else
        raise response.to_string
      end
    end
  end


  def self.create_handle handle, values, user_name
    values = values.collect do
      |value|
      value.handle_value
    end
    request = HDLLIB::CreateHandleRequest.new(
      handle.to_java_bytes,
      values.to_java( HDLLIB::HandleValue ),
      authenticationInfo( user_name )
    )
    response = resolver.processRequest( request )
    if response.kind_of? HDLLIB::ErrorResponse
      case response.responseCode
      when HDLLIB::ErrorResponse::RC_INSUFFICIENT_PERMISSIONS
        raise ReST::HTTPStatus, 'FORBIDDEN'
      else
        raise response.to_string
      end
    end
  end


  def self.update_handle handle, old_values, new_values, user_name
    authInfo = authenticationInfo( user_name )
    values_2b_added    = []
    values_2b_modified = []
    values_2b_removed  = []
    new_values.each do
      |new_value|
      # If the passed handle value is equal to the existing handle value in all
      # respects, and no timestamp is passed, then the old timestamp should be
      # used.
      old_value = old_values.find do
        |old_value|
        old_value.idx == new_value.idx
      end
      if ! old_value
        values_2b_added << new_value.handle_value
      elsif old_value and
          old_value.type != new_value.type ||
          old_value.data != new_value.data ||
          old_value.ttl_type != new_value.ttl_type ||
          old_value.ttl != new_value.ttl ||
          old_value.refs.any? do
              |ref1|
              new_value.refs.none? do
                |ref2|
                ref1[:idx]    == ref2[:idx] &&
                ref1[:handle] == ref2[:handle]
              end # new_value.refs.any? do
            end || #old_value.refs.all? do
          new_value.refs.any? do
              |ref1|
              old_value.refs.none? do
                |ref2|
                ref1[:idx]    == ref2[:idx] &&
                ref1[:handle] == ref2[:handle]
              end # old_value.refs.any?
            end # new_value.refs.all? do
        values_2b_modified << new_value.handle_value
      end
    end
    old_values.each do
      |old_value|
      if new_values.none? { |new_value| new_value.idx == old_value.idx }
        values_2b_removed << old_value.idx
      end
    end
    requests = []
    if ! values_2b_added.empty?
      requests << HDLLIB::AddValueRequest.new(
        handle.to_java_bytes,
        values_2b_added.to_java( HDLLIB::HandleValue ),
        authenticationInfo( user_name )
      )
    end
    if ! values_2b_modified.empty?
      requests << HDLLIB::ModifyValueRequest.new(
        handle.to_java_bytes,
        values_2b_modified.to_java( HDLLIB::HandleValue ),
        authenticationInfo( user_name )
      )
    end
    if ! values_2b_removed.empty?
      requests << HDLLIB::RemoveValueRequest.new(
        handle.to_java_bytes,
        values_2b_removed.to_java( Java::int ),
        authenticationInfo( user_name )
      )
    end
    requests.each do
      |request|
      response = resolver.processRequest( request )
      if response.kind_of? HDLLIB::ErrorResponse
        case response.responseCode
        when HDLLIB::ErrorResponse::RC_INSUFFICIENT_PERMISSIONS
          raise ReST::HTTPStatus, 'FORBIDDEN'
        else
          raise response.to_string
        end
      end
    end
  end


  def self.delete_handle handle, user_name
    authInfo = authenticationInfo( user_name )
    request = HDLLIB::DeleteHandleRequest.new(
      handle.to_java_bytes,
      authInfo
    )
    response = resolver.processRequest( request )
    if response.kind_of? HDLLIB::ErrorResponse
      case response.responseCode
      when HDLLIB::ErrorResponse::RC_INSUFFICIENT_PERMISSIONS
        raise ReST::HTTPStatus, 'FORBIDDEN'
      when HDLLIB::ErrorResponse::RC_HANDLE_NOT_FOUND
        raise ReST::HTTPStatus, 'NOT_FOUND'
      else
        raise response.to_string
      end
    end
  end


end # module HS
end # module EPIC
