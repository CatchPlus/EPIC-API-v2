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

require 'cgi'
require 'base64'

module EPIC


attr_writer :encoder
def encoder
  @encoder ||= ::EPIC::Encoder
end


# This is a mixin, to be included in resources that need to be serialized.
module Serialization
  CONTENT_TYPES = {
    'text/html' => :xml,
    'application/xhtml+xml' => :xml,
    'text/xml' => :xml,
    'application/xml' => :xml,
    'application/json' => :json,
    'application/x-json' => :json,
    'text/plain' => :txt
  }

  def preferred_type
    @preferred_type ||= request.preferred_type CONTENT_TYPES.keys
  end

  def preferred_serializer
    @preferred_serializer ||= CONTENT_TYPES[preferred_type]
  end

  def xhtml_breadcrumbs(p_path)
    segments = p_path.split('/')
    segments.pop
    return '' if segments.empty?
    bc_path = ''
    '<ul class="breadcrumb">' +
      segments.collect do |segment|
        bc_path += segment + '/'
        '<li><a href="' + bc_path + '" rel="' + (
          segment.empty? && 'home' || 'contents'
        ) + '">' + (
          segment.empty? && 'home' || CGI::unescape( segment, 'UTF-8' )
        ) + '</a><span class="divider">/</span></li>'
      end.join + '</ul>'
  end

  def xhtml_header(p_path)
    retval = <<-EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
      <html>
      <head>
      <link rel="stylesheet" href="/inc/bootstrap/bootstrap.min.css"/>
      <script type="text/javascript" src="/inc/jquery.js"></script> 
      <script type="text/javascript" src="/inc/jquery-tablesorter.js"></script> 
      <script type="text/javascript">//<![CDATA[
      $(document).ready(
        function() { $('.tablesorter').tablesorter(); } 
      );
      //]]></script>
    EOS
    retval << <<-EOS unless '/' == p_path
      <link rel="contents" href="#{ File::dirname(p_path).slashify }"/>
    EOS
    retval << <<-EOS << xhtml_breadcrumbs(p_path)
      <title>Index of #{ CGI::escapeHTML(CGI::unescape p_path) }</title>
      </head>
      <body>
    EOS
    retval
  end # xhtml_header

  def xhtml_footer(p_path = nil)
    '</body></html>'
  end # xhtml_footer

  def serialize_collection(p_how, p_path, p_columns, p_collection)
    case p_how
    when :xml
      stream do |out|
        p_columns.delete :uri
        p_columns.delete :name
        # +p_columns+ is now an Array of Symbols
        out << xhtml_header(p_path)
        out << <<-EOS
          <table class="tablesorter condensed-table bordered-table zebra-striped">
          <thead><tr><th>Name</th>
        EOS
        p_columns.each do |column|
          out << '<th>' << CGI.escapeHTML(
              column.to_s.split('_').collect{|word| word.capitalize}.join(' ')
            ) << '</th>'
        end
        out << '</tr></thead><tbody>'
        p_collection.each do |resource|
          resource[:name] ||= CGI::unescape(resource[:uri], 'UTF-8').unslashify
          out << <<-EOS
            <tr class="epic_resource">
            <td class="epic_name"><a href="#{resource[:uri]}">#{resource[:name]}</a></td>
          EOS
          p_columns.each do |column|
            out << '<td class="epic_' << column << '">' <<
              ( resource[column] || '' ) << '</td>'
          end
          out << '</tr>'
        end
        out << '</tbody></table>'<< xhtml_footer(p_path)
      end
    when :json
      stream do |out|
        out << '{'
        p_collection.each do |resource|
          out << (p_path + resource[:uri]).to_json() << ':' <<
            resource.reject {
              |key, value|
              key == :uri
            }.to_json
        end
        out << '}'
      end
    when :txt
      stream do |out|
        p_collection.each do |resource|
          out << resource[:uri] << CGI::EOL
        end
      end
    else
      erb 
    end
  end

  def as_json(p)
    case
    when p.kind_of?(Handle)
      {
        :handle => p.handle, 
        :values => p.values.inject({}) do |h, v|
          h[v.idx] = as_json v
        end
      }
    when p.kind_of?(HandleValue)
      retval = { :type => p.type, :data => p.data }
      [ :idx, :handle, :parsed_data ].each do |s|
        if t = p.send(s) then retval[s] = t end
      end
      retval
    when p.respond_to?(:to_json)
      p
    else
      raise ArgumentError, "Unsupported class: #{p.class}"  
    end

  end # as_json

end # module Encoder

end # module EPIC
