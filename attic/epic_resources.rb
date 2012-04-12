# Copyright �2011-2012 Pieter van Beek <pieterb@sara.nl>
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

require './epic_active_record.rb'

module EPIC


class HandleValue
  PERMS_BY_S = {
    :Add_Handle    => 0,
    :Delete_Handle => 1,
    :Add_NA        => 2,
    :Delete_NA     => 3,
    :Modify_Value  => 4,
    :Remove_Value  => 5,
    :Add_Value     => 6,
    :Read_Value    => 7,
    :Modify_Value  => 8,
    :Remove_Value  => 9,
    :Add_Admin     => 10,
    :List_Handles  => 11
  }
  PERMS_BY_I = PERMS_BY_S.invert
  attr_accessor :idx, :handle, :type, :data
  def initialize(args)
    [:idx, :handle, :type, :data].each do |s|
      if t = args[s] then instance_variable_set(:"@#{s}", t) end
    end
  end
  def parsed_data
    case type
    when 'HS_ADMIN'
      adminRecord = hdllib.AdminRecord.new
      hdllib.Encoder.decodeAdminRecord(
        data.to_java_bytes, 0, adminRecord
      )
      {
        :adminId => String.from_java_bytes( adminRecord.adminId ),
        :adminIdIndex => adminRecord.adminIdIndex,
        :perms => adminRecord.perms
      }
    else
      begin
        data.encode( 'UTF-8' )
      rescue
        nil
      end
    end
  end
  def parsed_data= (p_data)
    case type
    when 'HS_ADMIN'
      raise ArgumentError, 'Missing one or more required values' if
        ! p_data[:adminId] ||
        ! p_data[:adminIdIndex] ||
        ! p_data[:perms]
      adminRecord = hdllib.AdminRecord.new
      adminRecord.adminId = p_data[:adminId].to_s.to_java_bytes
      adminRecord.adminIdIndex = p_data[:adminIdIndex].to_i
      adminRecord.perms = p_data[:perms].collect do
        |perm| perm && true || false
      end
      self.data = String.from_java_bytes( hdllib.Encoder.encodeAdminRecord( adminRecord ) )
#        $logger.info @data.to_json
    else
      # @todo throw something
    end
    p_data
  end
  def serializable_hash
    retval = { :type => type, :data => Base64.strict_encode64(data) }
    [:idx, :handle, :parsed_data].each do |s|
      if t = self.send(s) then retval[s] = t end
    end
    retval
  end
end


class Handle

  attr_reader :prefix, :suffix, :handle

  def initialize(prefix, suffix, from_db = true)
    @prefix = prefix
    @suffix = suffix
    @handle = prefix + '/' + suffix
  end

  def self.suffixes(prefix)
    ActiveHandleValue.find_by_sql(
      "SELECT DISTINCT `handle` FROM `handles` WHERE `handle` LIKE '#{prefix}/%'"
    ).collect do |h|
      Regexp.new("^#{prefix}/(.*)").match(h.handle.to_s)[1]
    end
  end

  def values
    return @values if @values
    @values = ActiveHandleValue.where(:handle => handle).all.reduce({}) do
      |hash, activeHandleValue|
      hash[activeHandleValue.idx] = HandleValue.new(
        :idx => activeHandleValue.idx,
        :handle => handle,
        :type => activeHandleValue.type,
        :data => activeHandleValue.data
      )
      hash
    end
    if @values.empty? # <- assignment intended
      handleValue = hdllib.HandleValue.new
      @values = { 100 => HandleValue.new(
        :handle => handle,
        :idx => 100,
        :type => 'HS_ADMIN'
      ) }
      @values[100].parsed_data = {
        :adminId => CurrentUser::HANDLE,
        :adminIdIndex => CurrentUser::IDX,
        :perms => [
          :Add_Handle    => true,
          :Delete_Handle => true,
          :Add_NA        => false,
          :Delete_NA     => false,
          :Modify_Value  => true,
          :Remove_Value  => true,
          :Add_Value     => true,
          :Read_Value    => true,
          :Modify_Value  => true,
          :Remove_Value  => true,
          :Add_Admin     => true,
          :List_Handles  => false
        ]
      }
    end
    @values
  end
  def empty?
    values.size == 1 && values.first.type == 'HS_ADMIN'
  end
end


class Suffixes

  include Enumerable

  def initialize(prefix)
    @prefix = prefix
    @suffix_regexp = %r{^#{prefix}/(.*)}
  end

  def each
    ActiveHandleValue.
      select('`handle`').select('MIN(`id`) AS `id`').
      where('handle LIKE ?', "#{@prefix}/%").
      group(1).
      find_each do
        |row|
        yield @suffix_regexp.match(row.handle)[1]
      end
  end

  def to_xml

  end

  def to_json

  end

  def to_txt

  end

end


end
