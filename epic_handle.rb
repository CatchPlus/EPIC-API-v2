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
   
require 'base64'


module EPIC
  
  
class Handle < Collection
  
  DEFAULT_DEPTH = 'infiniy'
  
  attr_reader :prefix, :suffix, :handle, :handle_encoded
  
  def initialize path, activeHandleValues = nil
    super path
    raise "Invalid path #{path}" unless
      matches = %r{([^/]+)/([^/]+)\z}.match(path)
    @suffix = matches[2].unescape_path
    @prefix = matches[1].unescape_path
    @handle = @prefix + '/' + @suffix
    @handle_encoded = matches[0]
    if ! activeHandleValues
      activeHandleValues = ActiveHandleValue.where(:handle => @handle).all
    end
    @values = Hash[ activeHandleValues.collect { |v|
      [ v.idx.to_i, HandleValue.new( @handle_encoded + '/' + v.idx.to_s, v ) ]
    } ]
  end
  
  def enforce_admin_record
    unless @values.detect { |k, v| 'HS_ADMIN' === v.type }
      idx = 100
      idx += 1 while @values[idx]
      # In the JAVA code for the standard CNRI adminTool, the following code can
      # be found in private method +MainWindow::getDefaultAdminRecord()+:
      # 
      #   adminInfo.perms[AdminRecord.DELETE_HANDLE] = true;
      #   adminInfo.perms[AdminRecord.ADD_VALUE] = true;
      #   adminInfo.perms[AdminRecord.REMOVE_VALUE] = true;
      #   adminInfo.perms[AdminRecord.MODIFY_VALUE] = true;
      #   adminInfo.perms[AdminRecord.READ_VALUE] = true;
      #   adminInfo.perms[AdminRecord.ADD_ADMIN] = true;
      #   adminInfo.perms[AdminRecord.REMOVE_ADMIN] = true;
      #   adminInfo.perms[AdminRecord.MODIFY_ADMIN] = true;
      #   adminInfo.perms[AdminRecord.ADD_HANDLE] = true;
      #   adminInfo.perms[AdminRecord.LIST_HANDLES] = false;
      #   adminInfo.perms[AdminRecord.ADD_NAMING_AUTH] = false;
      #   adminInfo.perms[AdminRecord.DELETE_NAMING_AUTH] = false;
      #   return makeValueWithParams(100, Common.STD_TYPE_HSADMIN,
      #                              Encoder.encodeAdminRecord(adminInfo));
      @values[idx] = HandleValue.new @handle_encoded + '/' + idx.to_s
      @values[idx].type = 'HS_ADMIN'
      @values[idx].parsed_data = {
        :adminId => CurrentUser::HANDLE,
        :adminIdIndex => CurrentUser::IDX,
        :perms => [
          :add_handle    => true,
          :delete_handle => true,
          :add_NA        => false,
          :delete_NA     => false,
          :modify_value  => true,
          :remove_value  => true,
          :add_value     => true,
          :read_value    => true,
          :modify_admin  => true,
          :remove_admin  => true,
          :add_admin     => true,
          :list_handles  => false
        ]
      }
    end
  end
  
  def each
    @values.values.sort { |a,b| a.idx <=> b.idx }.each do |v|
      yield( {
        :uri => v.idx.to_s,
        :name => @handle + ':' + v.idx.to_s,
        :idx => v.idx.to_s,
        :type => v.type,
        :data => Base64.encode64( v.data ),
        :parsed_data => v.parsed_data
      } )
    end
  end
  
  def empty?
    @values.empty?
  end
  
end # class Handle


end # module EPIC
