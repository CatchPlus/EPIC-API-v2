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

require './epic_resource.rb'
require './epic_hs.rb'
require 'base64'

module EPIC


class HandleValue < Resource

  CONTENT_TYPES = {
    'application/xhtml+xml; charset=UTF-8' => 1,
    'text/html; charset=UTF-8' => 1,
    'text/xml; charset=UTF-8' => 1,
    'application/xml; charset=UTF-8' => 1,
    'application/json; charset=UTF-8' => 0.5,
    'application/x-json; charset=UTF-8' => 0.5,
    'application/octet-stream' => 0.9,
  }

  def do_GET request, response
    bct = request.best_content_type CONTENT_TYPES
    response.header['Content-Type'] = bct
    response.body =
      case bct.split( ';' ).first
      when 'application/json', 'application/x-json'
        JSON.new self
      when 'application/octet-stream'
        BIN.new self
      else
        XHTML.new self
      end
  end

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
  def initialize path, dbrow = nil # :params: String path, Hash dbrow
    super path
    matches = %r{/([^/]+/[^/]+)(/\d+)\z}.match path
    raise Djinn::HTTPStatus, '500' unless matches
    @handle = matches[1].unescape_path
    @idx = matches[2].to_i
    if dbrow
      @type      = dbrow[:type].to_s
      @data      = dbrow[:data].to_s
      @ttl_type  = dbrow[:ttl_type].to_i
      @ttl       = dbrow[:ttl].to_i
      @timestamp = dbrow[:timestamp].to_i
      @refs      = dbrow[:refs].split("\t").collect do
        |ref|
        ref = ref.split ':', 2
        {
          :idx    => ref[0].to_i,
          :handle => ref[1]
        }
      end
      @admin_read  = dbrow[:admin_read]  && 0 != dbrow[:admin_read]
      @admin_write = dbrow[:admin_write] && 0 != dbrow[:admin_write]
      @pub_read    = dbrow[:pub_read]    && 0 != dbrow[:pub_read]
      @pub_write   = dbrow[:pub_write]   && 0 != dbrow[:pub_write]
    else
      @type      = String.from_java_bytes HS::EMPTY_HANDLE_VALUE.getType
      @data      = String.from_java_bytes HS::EMPTY_HANDLE_VALUE.getData
      @ttl_type  = HS::EMPTY_HANDLE_VALUE.getTTLType
      @ttl       = HS::EMPTY_HANDLE_VALUE.getTTL
      @timestamp = HS::EMPTY_HANDLE_VALUE.getTimestamp
      @refs      = HS::EMPTY_HANDLE_VALUE.getReferences.collect do
        |valueReference|
        {
          :idx    => valueReference.index,
          :handle => String.from_java_bytes( valueReference.handle )
        }
      end
      @admin_read  = HS::EMPTY_HANDLE_VALUE.getAdminCanRead
      @admin_write = HS::EMPTY_HANDLE_VALUE.getAdminCanWrite
      @pub_read    = HS::EMPTY_HANDLE_VALUE.getAnyoneCanRead
      @pub_write   = HS::EMPTY_HANDLE_VALUE.getAnyoneCanWrite
    end
  end

  def parsed_data
    case type
    when 'HS_ADMIN'
      HS.parse_HS_ADMIN self.data
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
