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

require './epic_collection.rb'
require './epic_sequel.rb'
require './epic_hs.rb'
require 'base64'
require 'time'

module EPIC


class Handle < Resource

  CONTENT_TYPES = {
    'application/xhtml+xml; charset=UTF-8' => 1,
    'text/html; charset=UTF-8' => 1,
    'text/xml; charset=UTF-8' => 1,
    'application/xml; charset=UTF-8' => 1,
    'application/json; charset=UTF-8' => 0.5,
    'application/x-json; charset=UTF-8' => 0.5,
    'text/plain; charset=UTF-8' => 0.1
  }

  attr_reader :prefix, :suffix, :handle, :handle_encoded, :values

=begin rdoc
[handleValues]
  Defaults to +nil+ if unspecified, causing the Handle Values to be read from
  the database. If you want to create a new Handle without any values, pass an
  empty hash +{}+.
=end
  def initialize path, handleValues = nil
    super path
    raise Djinn::HTTPStatus, '500' unless
      matches = %r{([^/]+)/([^/]+)\z}.match(path)
    @suffix = matches[2].unescape_path
    @prefix = matches[1].unescape_path
    @handle = @prefix + '/' + @suffix
    @handle_encoded = matches[0]
    unless handleValues
      handleValues = DB.instance.all_handle_values(self.handle).collect do
        |row|
        HandleValue.new self.path + '/' + row[:idx].to_s, row
      end
    end
    @values = Hash[ handleValues.collect { |v| [ v.idx, v ] } ]
  end

  def do_GET request, response
    bct = request.best_content_type CONTENT_TYPES
    response.header['Content-Type'] = bct
    response.body =
      case bct.split( ';' ).first
      when 'application/json', 'application/x-json'
        JSON.new self, request
      when 'text/plain'
        TXT.new self, request
      else
        XHTML.new self, request
      end
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
      userInfo = EPIC::USERS[self.userName]
      @values[idx] = HandleValue.new @handle_encoded + '/' + idx.to_s
      @values[idx].type = 'HS_ADMIN'
      @values[idx].parsed_data = {
        :adminId => userInfo[:handle],
        :adminIdIndex => userInfo[:index],
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

  def to_a
    @values.values.sort { |a,b| a.idx <=> b.idx }.collect {
      |v|
      {
        :IDX => v.idx.to_s,
        :type => v.type.to_s,
        :'Data (Parsed)' => v.parsed_data,
        :'Data (Base64 encoded)' => Base64.encode64(v.data),
        :timestamp => Time.at(v.timestamp).utc.rfc2822, #rfc2822(Time.at(v.timestamp)),
        :TTL => v.ttl.to_s + ( 0 == v.ttl_type ? ' (rel)' : ' (abs)' ),
        :refs => v.refs.collect {
                   |ref|
                   ref[:idx].to_s + ':' + ref[:handle]
                 }.join('<br/>'),
        :perms => (
          (v.admin_read  ? 'r' : '-') +
          (v.admin_write ? 'w' : '-') +
          (v.pub_read  ? 'r' : '-') +
          (v.pub_write ? 'w' : '-')
        )
      }
    }
    # do |v|
      # yield( {
        # :uri => v.idx.to_s,
        # :name => @handle + ':' + v.idx.to_s,
        # :idx => v.idx.to_s,
        # :type => v.type,
        # :data => Base64.encode64( v.data ),
        # :parsed_data => v.parsed_data
      # } )
    # end
  end

  def empty?
    @values.empty?
  end

end # class Handle


class Handle::XHTML < Serializer::XHTML

  def each_nested # :yields: strings
    yield self.serialize self.resource.to_a
    # yield '
# <table class="epic_handle table table-striped table-bordered table-condensed">
# <caption>' + resource.handle.escape_html + '</caption>
# <thead><tr>
# <th class="epic_idx">IDX</th>
# <th class="epic_type">Type</th>
# <th class="epic_data">Data (base64)</th>
# <th class="epic_parsed">Data (parsed)</th>
# <th class="epic_timestamp">Timestamp</th>
# <th class="epic_ttl">TTL</th>
# <th class="epic_refs">Refs</th>
# <th class="epic_perms">Perms</th></tr></thead><tbody>'
    # self.resource.each do
      # |hv|
      # html = '
# <tr class="epic_handle_value">
# <td class="epic_idx">' + hv.idx.to_s + '</td>
# <td class="epic_type">' + hv + '</td>
# <td class="epic_data">' + hv + '</td>
# <td class="epic_parsed">' + hv + '</td>
# <td class="epic_">' + hv + '</td>
# <td class="epic_">' + hv + '</td>
# <td class="epic_">' + hv + '</td>
# <td class="epic_">' + hv + '</td>
# <td class="epic_">' + hv + '</td>
# <td class="epic_">' + hv + '</td>'
  end

end # class Collection::XHTML


end # module EPIC
