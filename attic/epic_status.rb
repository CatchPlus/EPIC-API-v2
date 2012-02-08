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

require 'rexml/document'

module EPIC


class HTTPStatus
  
  include Rack::Utils

  attr_reader :status, :info
  
  # @param p_status HTTP/1.1 status code
  # @param p_message Depends on the status code.
  def initialize(p_status, *p_info)
    @status = p_status.to_i
    @info = p_info
  end
  
  def response(p_request)
    headers = { 'Content-Type' => 'text/xhtml; charset="UTF-8"' }
    retval = EPIC::Utils::xhtml_header p_request.path
    retval << '<h1>HTTP/1.1 ' + status.to_s + ' ' +
      escape_html( HTTP_STATUS_CODES[@status] ) + '</h1>'
    case @status
    when 300...400
      @info = @info.to_s
      headers['Location'] = @info
      retval << '<a href="' + @info.to_s + '">' + @info.to_s + '</a>'
    else
      begin
        REXML::Document.new \
          '<?xml version="1.0" encoding="UTF-8" ?>' +
          '<div>' + p_message + '</div>'
        @message = p_message.to_s
      rescue
        @message = escape_html( p_message.to_s )
      end
    end
  end
  
end # class HTTPStatus


end # module EPIC
