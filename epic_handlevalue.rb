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

require 'epic_resource.rb'
require 'base64'

module EPIC


class HandleValue < Resource

  def content_types
    { 
      'application/octet-stream' => 0.9,
      'application/json; charset=UTF-8' => 1
    }
  end

  def do_GET request, response
    response.body = case response.header['Content-Type'].to_s.split( ';' ).first.strip
    when 'application/json'
      JSON.new self
    else
      BIN.new self
    end
  end

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

  EMPTY_HANDLE_VALUE = hdllib.HandleValue.new

  attr_accessor :handle, :idx, :type, :data, :ttl_type, :ttl, :timestamp,
    :refs, :admin_read, :admin_write, :pub_read, :pub_write
  # Some metaprogramming to delegate data access to the appropriate
  # ActiveHandleValue instance property @active_handle_value. 
#  [ :handle, :idx, :data, :type ].each do
#    |symbol|
#    def_delegator :@active_handle_value, symbol
#    def_delegator :@active_handle_value, :"#{symbol}="
#  end

  # Can be called with either an ActiveHandleValue object, or with a hash of
  # key => value pairs.
  def initialize path, ahv = nil # :params: String path, ActiveHandleValue ahv
    super path
    matches = %r{([^/]+/[^/]+)/(\d+)\z}.match path
    raise "Couldn't parse path #{path}" unless matches
    @handle = matches[1].unescape_path
    @idx = matches[2]
    if ahv
      @type      = ahv.type.to_s
      @data      = ahv.data.to_s
      @ttl_type  = ahv.ttl_type.to_i
      @ttl       = ahv.ttl.to_i
      @timestamp = ahv.timestamp.to_i
      @refs      = ahv.refs.split("\t").collect do
        |ref|
        ref = ref.split ':', 2
        {
          :idx    => ref[0].to_i,
          :handle => ref[1]
        }
      end
      @admin_read  = ahv.admin_read  && 0 != ahv.admin_read
      @admin_write = ahv.admin_write && 0 != ahv.admin_write
      @pub_read    = ahv.pub_read    && 0 != ahv.pub_read
      @pub_write   = ahv.pub_write   && 0 != ahv.pub_write
    else
      @type      = String.from_java_bytes EMPTY_HANDLE_VALUE.getType
      @data      = String.from_java_bytes EMPTY_HANDLE_VALUE.getData
      @ttl_type  = EMPTY_HANDLE_VALUE.getTTLType
      @ttl       = EMPTY_HANDLE_VALUE.getTTL
      @timestamp = EMPTY_HANDLE_VALUE.getTimestamp
      @refs      = EMPTY_HANDLE_VALUE.getReferences.collect do
        |valueReference|
        {
          :idx    => valueReference.index,
          :handle => String.from_java_bytes( valueReference.handle )
        }
      end
      @admin_read  = EMPTY_HANDLE_VALUE.getAdminCanRead
      @admin_write = EMPTY_HANDLE_VALUE.getAdminCanWrite
      @pub_read    = EMPTY_HANDLE_VALUE.getAnyoneCanRead
      @pub_write   = EMPTY_HANDLE_VALUE.getAnyoneCanWrite
    end
  end

  def parsed_data
    case type
    when 'HS_ADMIN'
      adminRecord = hdllib.AdminRecord.new
      hdllib.Encoder.decodeAdminRecord(
        self.data.to_java_bytes, 0, adminRecord
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
    else
      begin
        self.data.encode( 'UTF-8' )
      rescue
        nil
      end
    end
  end

  def parsed_data= (p_data)
    case type
    when 'HS_ADMIN'
      raise Djinn::HTTPStatus, '500 Missing one or more required values' if
        ! p_data[:adminId] ||
        ! p_data[:adminIdIndex] ||
        ! p_data[:perms]
      adminRecord = hdllib.AdminRecord.new
      adminRecord.adminId = p_data[:adminId].to_s.to_java_bytes
      adminRecord.adminIdIndex = p_data[:adminIdIndex].to_i
      adminRecord.perms = p_data[:perms].collect {
        |perm| perm && true || false
      }.to_java Java::boolean
      self.data = String.from_java_bytes(
        hdllib.Encoder.encodeAdminRecord( adminRecord )
      )
    else
      raise Djinn::HTTPStatus,
        "500 parsed_data=() not implemented for type #{type}"
    end
    p_data
  end

  def serializable_hash
    retval = {
      :type => self.type,
      :data => Base64.strict_encode64(self.data)
    }
    [ :idx, :handle, :parsed_data ].each do
      |s|
      if t = self.send(s) then retval[s] = t end
    end
    retval
  end

end # class HandleValue


class HandleValue::BIN < Serializer::BIN
  def each
    yield 'binary respresentation'
  end
end # class HandleValue::XHTML


class HandleValue::JSON < Serializer::JSON
  def each
    yield '"hello"'
  end
end # class HandleValue::TXT


end # module EPIC
