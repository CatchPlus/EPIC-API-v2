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

require './epic_resource.rb'
require './epic_hs.rb'

module EPIC


class HandleValue # < Resource


  attr_accessor :idx, :type, :data, :ttl_type, :ttl, :timestamp,
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
  def initialize dbrow = nil # :params: String path, Hash dbrow
    # super path
    # matches = %r{/([^/]+/[^/]+)/(\d+)\z}.match path
    # raise Djinn::HTTPStatus, '500' unless matches
    # @handle = matches[1].unescape_path
    # @idx = matches[2].to_i
    if dbrow
      @idx       = dbrow[:idx].to_i
      @type      = dbrow[:type].to_s
      @data      = dbrow[:data].to_s
      @ttl_type  = dbrow[:ttl_type].to_i
      @ttl       = dbrow[:ttl].to_i
      @timestamp = dbrow[:timestamp].to_i
      @refs      = self.class.string2refs( dbrow[ :refs ] )
      @admin_read  = dbrow[:admin_read]  && 0 != dbrow[:admin_read]
      @admin_write = dbrow[:admin_write] && 0 != dbrow[:admin_write]
      @pub_read    = dbrow[:pub_read]    && 0 != dbrow[:pub_read]
      @pub_write   = dbrow[:pub_write]   && 0 != dbrow[:pub_write]
    else
      @idx       = HS::EMPTY_HANDLE_VALUE.getIndex
      @type      = String.from_java_bytes HS::EMPTY_HANDLE_VALUE.getType
      @data      = String.from_java_bytes HS::EMPTY_HANDLE_VALUE.getData
      @ttl_type  = HS::EMPTY_HANDLE_VALUE.getTTLType
      @ttl       = HS::EMPTY_HANDLE_VALUE.getTTL
      @timestamp = Time.new.to_i
      @refs      = HS::EMPTY_HANDLE_VALUE.getReferences.to_a.collect do
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


  def self.refs2string refs
    refs.collect do
      |ref|
      ref[:idx].to_s + ':' + ref[:handle]
    end.join( "\t" )
  end


  def self.string2refs string
    string.split("\t").collect do
      |ref|
      ref = ref.split ':', 2
      {
        :idx    => ref[0].to_i,
        :handle => ref[1]
      }
    end
  end


  def parsed_data
    case type
    when 'HS_ADMIN'
      HS.unpack_HS_ADMIN self.data
    else
      begin
        retval = self.data.encode( Encoding::UTF_8 )
        %r{[\x00-\x08\x0B\x0C\x0E-\x1F]}.match(retval) ? nil : retval
      rescue
        nil
      end
    end
  end


  def parsed_data= p_data
    self.data = case type
    when 'HS_ADMIN'
      HS.pack_HS_ADMIN p_data
    else
      p_data.to_s
    end
  end


end # class HandleValue


end # module EPIC
