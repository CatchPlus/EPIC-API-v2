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

require './epic_hs.rb'

module EPIC


class HandleValue # < Resource


  class << self


    private


    def map_java_bytes java_name, ruby_name
      define_method ruby_name do
        String.from_java_bytes(
          @handle_value.send( :"get#{java_name}" )
        )
      end
      define_method :"#{ruby_name}=" do
        |value|
        @handle_value.send( :"set#{java_name}", value.to_java_bytes )
        value
      end
    end


    def map_java java_name, ruby_name
      define_method ruby_name do
        @handle_value.send( :"get#{java_name}" )
      end
      define_method :"#{ruby_name}=" do
        |value|
        @handle_value.send( :"set#{java_name}", value )
        value
      end
    end


  end # class << self

  map_java_bytes :Type, :type
  map_java_bytes :Data, :data
  map_java :Index, :idx
  map_java :TTL, :ttl
  map_java :TTLType, :ttl_type
  map_java :Timestamp, :timestamp
  map_java :AdminCanRead,   :admin_read
  map_java :AdminCanWrite,  :admin_write
  map_java :AnyoneCanRead,  :pub_read
  map_java :AnyoneCanWrite, :pub_write


  def refs
    @handle_value.getReferences.to_a.collect do
      |ref|
      { :idx => ref.index, :handle => String.from_java_bytes( ref.handle ) }
    end
  end


  def refs= p_refs
    @handle_value.setReferences(
      p_refs.collect do
        |ref|
        HS.hdllib.ValueReference.new(
          ref[:handle].to_java_bytes,
          ref[:idx]
        )
      end.to_java HS.hdllib.ValueReference
    )
  end


  attr_reader :handle_value
  # attr_accessor :idx, :type, :data, :ttl_type, :ttl, :timestamp,
  #   :refs, :admin_read, :admin_write, :pub_read, :pub_write
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
    @handle_value = HS.hdllib.HandleValue.new
    if dbrow
      self.idx       = dbrow[:idx].to_i
      self.type      = dbrow[:type].to_s
      self.data      = dbrow[:data].to_s
      self.ttl_type  = dbrow[:ttl_type].to_i
      self.ttl       = dbrow[:ttl].to_i
      self.timestamp = dbrow[:timestamp].to_i
      @handle_value.setReferences(
        dbrow[ :refs ].split("\t").collect do
          |ref|
          ref = ref.split ':', 2
          HS.hdllib.ValueReference.new(
            ref[1].to_java_bytes,
            ref[0].to_i
          )
        end.to_java hdllib.ValueReference
      )
      self.admin_read  = dbrow[:admin_read]  && 0 != dbrow[:admin_read]
      self.admin_write = dbrow[:admin_write] && 0 != dbrow[:admin_write]
      self.pub_read    = dbrow[:pub_read]    && 0 != dbrow[:pub_read]
      self.pub_write   = dbrow[:pub_write]   && 0 != dbrow[:pub_write]
    else
      self.timestamp = Time.new.to_i
    end
  end


  # def self.refs2string refs
    # refs.collect do
      # |ref|
      # ref[:idx].to_s + ':' + ref[:handle]
    # end.join( "\t" )
  # end
# 
# 
  # def self.string2refs string
    # string.split("\t").collect do
      # |ref|
      # ref = ref.split ':', 2
      # {
        # :idx    => ref[0].to_i,
        # :handle => ref[1]
      # }
    # end
  # end


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
