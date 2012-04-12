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
   
require 'djinn_restserver.rb'
require 'base64'
require 'java'
require 'hsj/handle.jar'
require 'hsj/cnriutil.jar'


module EPIC
  
  
# Base class of all resources in this web service.
class Resource
  include Djinn::Resource
end


# Base class for all serializers. 
class Serializer
  
  include Enumerable
  
  attr_reader :resource, :request
  
  def initialize resource, request
    @resource = resource
    @request = request
  end
  
  def requested?
    self.resource.path.slashify == request.path.slashify
  end
  
  def recurse?
    depth = ( self.resource.class.constants.include? :DEFAULT_DEPTH ) ?
      self.resource.class::DEFAULT_DEPTH.to_s : '0'
    depth = request.env['HTTP_DEPTH'] || depth
    requested? && '0' != depth || 'infinity' == depth
  end

end # class Serializer


class Serializer::TXT < Serializer; end

class Serializer::JSON < Serializer; end

class Serializer::XHTML < Serializer
  
  def breadcrumbs
    segments = request.path.split('/')
    segments.pop
    return '' if segments.empty?
    bc_path = ''
    '<ul class="breadcrumb">' + segments.collect do
      |segment|
      bc_path += segment + '/'
      '<li><a href="' + bc_path + '" rel="' + (
        segment.empty? && 'home' || 'contents'
      ) + '">' + (
        segment.empty? && 'home' || segment.unescape_path
      ) + '</a><span class="divider">/</span></li>'
    end.join + '</ul>'
  end # def breadcrumbs
    
  def header
    return '' if !requested? || request.xhr?
    retval =
'<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<link rel="stylesheet" href="/inc/bootstrap/bootstrap.min.css"/>'
# <script type="text/javascript" src="/inc/jquery-1.7.1.min.js"></script> 
# <script type="text/javascript" src="/inc/jquery-tablesorter.js"></script> 
# <script type="text/javascript">//<![CDATA[
# $(document).ready(
  # function() { $(".tablesorter").tablesorter(); } 
# );
# //]]></script>'
    unless '/' == request.path[-1, 1] # unless request.path ends with a slash
      retval << '<base href="' << request.path.slashify << '"/>'
    end
    unless '/' == request.path
      retval << '<link rel="contents" href="' << File::dirname(request.path).slashify << '"/>'
    end
    retval << '<title>Index of ' << request.path.unescape_path.escape_html <<
      '</title></head><body>' << breadcrumbs
    retval
  end # header
  
  def footer
    if !requested? || request.xhr?
      ''
    else
      '<p align="right"><em>Developed for <a href="http://www.catchplus.nl/">CATCH+</a><br/>by <a href="http://www.sara.nl/">SARA</a></em></p></body></html>'
    end
  end # footer
  
  def serialize p
    case
    when p.kind_of?( Hash )
      '<table class="condensed-table bordered-table zebra-striped">' +
      p.collect {
        |key, value|
        '<tr><th>' + key.to_s.split('_').collect{
          |word|
          word[0..0].upcase + word[1..-1]
        }.join(' ').escape_html +
        '</th><td class="epic_' + key.to_s.escape_html + '">' + self.serialize( value ) + "</td></tr>\n"
      }.join + '</table>'
    when p.kind_of?( Enumerable )
      begin
        raise 'dah' unless p.first.kind_of?( Hash )
        keys = p.first.keys
        p.each {
          |value|
          raise 'dah' unless value.keys == keys
        }
        '<table class="tablesorter condensed-table bordered-table zebra-striped"><thead><tr>' +
        keys.collect {
          |column|
          '<th>' +
          column.to_s.split('_').collect{
            |word|
            word[0..0].upcase + word[1..-1]
          }.join(' ').escape_html +
          "</th>\n"
        }.join + '</tr></thead><tbody>' + p.collect {
          |h|
          '<tr>' + h.collect {
            |key, value|
            '<td class="epic_' + key.to_s.escape_html + '">' +
            item[column].to_s.escape_html + "</td>\n"
          }.join + '</tr>'
        }.join + "</tbody></table>"
      rescue
        '<ul class="unstyled">' + p.collect {
          |value|
          '<li>' + self.serialize(value) + "</li>\n"
        }.join + "</ul>\n"
      end
    else
      p.to_s.escape_html
    end
  end
  
end # class Serializer::XHTML

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


class Handles < Collection
  
  def prefix
    @prefix ||= File::basename(path.unslashify).unescape_path
  end
  
  def each
    ActiveHandleValue.select(:handle).uniq.
      where('`handle` LIKE ?', self.prefix + '/%').
      find_each do |ahv|
        suffix = %r{\A[^/]+/(.*)}.match(ahv.handle)[1]
        yield( { :uri => suffix.escape_path, :name => "#{prefix}/#{suffix}" } )
      end
  end
  
end # class Handles


class NAs < Collection

  def self.all
    @all ||= ActiveNA.all.collect { |na| na.na }
  end
  def all; self.class.all; end

  def each
    all_what = File.basename(path).unescape_path
    all.each do |na|
      matches = %r{\A0.NA/(.*)}i.match(na)
      na = matches[1] if matches
      yield( {
        :uri => na.escape_path + '/',
        :description => "All #{all_what} for prefix 0.NA/#{na.escape_html}"
      } )
    end
  end

end # class NAs


end # module EPIC
