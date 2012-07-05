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
require 'json'
# By default, the json gem uses the +Ext+ parser and generator, which uses a
# fast Java implementation. We use the +Pure+ parser and generator, because it
# seems Unicode characters better. This is strange, as these two implementations
# should behave identically.
require 'json/pure'

module EPIC


class Handle < Resource


  CONTENT_TYPES = {
    'application/xhtml+xml; charset=UTF-8' => 1,
    'text/html; charset=UTF-8' => 1,
    'text/xml; charset=UTF-8' => 1,
    'application/xml; charset=UTF-8' => 1,
    'application/json; charset=UTF-8' => 0.5,
    'application/x-json; charset=UTF-8' => 0.5
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
    handleValues ||= DB.instance.all_handle_values(self.handle)
    @values = handleValues.collect do
      |row|
      HandleValue.new row
    end
  end


  def do_GET request, response
    bct = request.best_content_type CONTENT_TYPES
    response.header['Content-Type'] = bct
    response.body =
      case bct.split( ';' ).first
      when 'application/json', 'application/x-json'
        JSON.new self, request
      else
        XHTML.new self, request
      end
  end


  def do_PUT request, response
    case request.media_type
    when 'application/json', 'application/x-json'
      begin
        handle_values_in = ::JSON.parse(
          request.body.read,
          :symbolize_names => true
        )
      rescue
        raise Djinn::HTTPStatus, 'BAD_REQUEST ' + $!.to_s
      end # begin
    else
      raise Djinn::HTTPStatus, 'UNSUPPORTED_MEDIA_TYPE application/json'
    end # case request.media_type
    raise Djinn::HTTPStatus, 'BAD_REQUEST Array expected' \
      unless handle_values_in.kind_of? Array
    values = handle_values_in.collect do
      |handle_value_in|
      handle_value = HandleValue.new
      handle_value.idx = handle_value_in[:idx].to_i \
        if handle_value_in.key? :idx
      handle_value.type = handle_value_in[:type].to_s \
        if handle_value_in.key? :type
      handle_value.data = Base64.decode64( handle_value_in[:data].to_s ) \
        if handle_value_in.key? :data
      if handle_value_in.key?( :data ) &&
         handle_value_in.key?( :parsed_data )
        data = handle_value.data
        parsed_data = handle_value.parsed_data
        handle_value.parsed_data = handle_value_in[:parsed_data]
        unless data == handle_value.data ||
               parsed_data == handle_value.parsed_data
          raise Djinn::HTTPStatus, 'BAD_REQUEST Handle Value contains both <tt>data</tt> and <tt>parsed_data</tt>, and their contents are not semantically equal.'
        end # unless
      elsif handle_value_in.key?( :parsed_data )
        handle_value.parsed_data = handle_value_in[:parsed_data]
      end # if
      handle_value.ttl_type = handle_value_in[:ttl_type].to_i \
        if handle_value_in.key? :ttl_type
      handle_value.ttl = handle_value_in[:ttl].to_i \
        if handle_value_in.key? :ttl
      handle_value.refs = handle_value_in[:refs] \
        if handle_value_in[:refs].kind_of?( Array ) &&
           handle_value_in[:refs].all? do
             |ref|
             ref.kind_of?( Hash ) &&
             ref[:idx].kind_of?( Integer ) &&
             ref[:handle].kind_of?( String )
           end
      handle_value.admin_read = !!handle_value_in[:admin_read] \
        if handle_value_in.key? :admin_read
      handle_value.admin_write = !!handle_value_in[:admin_write] \
        if handle_value_in.key? :admin_write
      handle_value.pub_read = !!handle_value_in[:pub_read] \
        if handle_value_in.key? :pub_read
      handle_value.pub_write = !!handle_value_in[:pub_write] \
        if handle_value_in.key? :pub_write
      # If the passed handle value is equal to the existing handle value in all
      # respects, and no timestamp is passed, then the old timestamp should be
      # used.
      if handle_value_in.key? :timestamp
        handle_value.timestamp = handle_value_in[:timestamp].to_i
      else
        current_value = @values.find do
          |value|
          value.idx == handle_value.idx &&
          value.type == handle_value.type &&
          value.data == handle_value.data &&
          value.ttl_type == handle_value.ttl_type &&
          value.ttl == handle_value.ttl &&
          value.refs.all? do
            |ref1|
            handle_value.refs.any? do
              |ref2|
              ref1[:idx]    == ref2[:idx] &&
              ref1[:handle] == ref2[:handle]
            end # handle_value.refs.any? do
          end && #value.refs.all? do
          handle_value.refs.all? do
            |ref1|
            value.refs.any? do
              |ref2|
              ref1[:idx]    == ref2[:idx] &&
              ref1[:handle] == ref2[:handle]
            end # value.refs.any?
          end # handle_value.refs.all? do
        end
        if current_value
          handle_value.timestamp = current_value.timestamp
        end
      end
      $stderr.puts handle_value.inspect
      handle_value
    end # values = handle_values_in.collect do
    self.class.enforce_proper_indexes values
    self.class.enforce_admin_record values, request.env['REMOTE_USER']
    if self.empty?
      EPIC::HS.create(self.handle, values, request.env['REMOTE_USER'])
      @values = values
      raise Djinn::HTTPStatus, 'CREATED ' + self.path
    else
      EPIC::HS.delete(self.handle, request.env['REMOTE_USER'])
      EPIC::HS.create(self.handle, values, request.env['REMOTE_USER'])
      @values = values
      response.status = status_code(:no_content)
    end
  end


  def self.enforce_proper_indexes values
    all_indexes = []
    values.each do
      |value|
      next if HS::EMPTY_HANDLE_VALUE.getIndex == value.idx
      raise( Djinn::HTTPStatus, "BAD_REQUEST Multiple values with index #{value.idx}" ) \
        if all_indexes.member? value.idx
      all_indexes << value.idx
    end
    current_index = 1
    values.each do
      |value|
      next unless HS::EMPTY_HANDLE_VALUE.getIndex == value.idx
      current_index = current_index + 1 while all_indexes.member? current_index
      value.idx = current_index
      all_indexes << current_index
    end
    values
  end


  def self.enforce_admin_record values, user_name
    unless values.any? { |v| 'HS_ADMIN' === v.type }
      idx = 100
      idx += 1 while values.any? { |v| idx === v.idx }
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
      user_info = EPIC::USERS[user_name]
      admin_record = HandleValue.new
      admin_record.idx = idx
      admin_record.type = 'HS_ADMIN'
      admin_record.parsed_data = {
        :adminId => user_info[:handle],
        :adminIdIndex => user_info[:index],
        :perms => {
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
        }
      }
      values << admin_record
    end
    values
  end


  def to_a
    @values.sort { |a,b| a.idx <=> b.idx }.collect {
      |v|
      {
        :idx => v.idx.to_i,
        :type => v.type.to_s,
        :parsed_data => v.parsed_data,
        :data => Base64.encode64(v.data).chomp,
        :timestamp => v.timestamp.to_i, #rfc2822(Time.at(v.timestamp)),
        :ttl_type => v.ttl_type.to_i,
        :ttl => v.ttl.to_i,
        :refs => v.refs.collect { |ref| ref[:idx].to_s + ':' + ref[:handle] },
        :admin_read  => !!v.admin_read,
        :admin_write => !!v.admin_write,
        :pub_read    => !!v.pub_read,
        :pub_write   => !!v.pub_write
      }
    }
  end


  def empty?
    @values.empty?
  end

end # class Handle


class Handle::XHTML < Serializer::XHTML


  def each_nested # :yields: strings
    values = self.resource.to_a
    values.each do
      |value|
      value[:timestamp] = Time.at(value[:timestamp]).utc.xmlschema
      value[:ttl] = ( 0 == value[:ttl_type] ) ?
        value[:ttl].to_s + 's' :
        Time.at(value[:ttl]).utc.xmlschema
      value.delete :ttl_type
      value[:perms] =
        ( value[:admin_read]  ? 'r' : '-' ) +
        ( value[:admin_write] ? 'w' : '-' ) +
        ( value[:pub_read]    ? 'r' : '-' ) +
        ( value[:pub_write]   ? 'w' : '-' )
      value.delete :admin_read
      value.delete :admin_write
      value.delete :pub_read
      value.delete :pub_write
    end
    yield self.serialize values
  end


end # class Collection::XHTML


class Handle::JSON < Serializer::JSON


  def each
    yield ::JSON::pretty_generate( self.resource.to_a )
  end


end # class Handle::JSON


end # module EPIC
