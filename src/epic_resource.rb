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

require 'rackful'

module EPIC


class XHTML < Rackful::XHTML

  def breadcrumbs
    segments = Rackful::Request.current.path.split('/')
    segments.pop
    return '' if segments.empty?
    bc_path = ''
    '<ul class="breadcrumb">' + segments.collect do
      |segment|
      bc_path += segment + '/'
      '<li><a href="' + bc_path + '" rel="' + (
        segment.empty? && 'home' || 'contents'
      ) + '">' + (
        segment.empty? && 'home' || segment.to_path.unescape
      ) + '</a><span class="divider">/</span></li>'
    end.join + '</ul>'
  end

  def header
    <<EOS
<link rel="stylesheet" href="/inc/bootstrap/css/bootstrap.min.css"/>
<link rel="stylesheet" href="/inc/bootstrap/css/bootstrap-responsive.min.css"/>
<!--<link rel="stylesheet/less" type="text/css" href="/inc/epic.less"/>-->
<title>#{Rack::Utils.escape_html( resource.title )}</title></head>
<body>#{self.breadcrumbs}#{resource.xhtml}
<script src="/inc/jquery.js" type="text/javascript"></script>
<script type="text/javascript">
  window.onload = function() {
    $("dl.rackful-object").addClass("dl-horizontal");
    $("table.rackful-objects").addClass("table table-striped table-condensed table-bordered");
  }
</script>
EOS
  end # header

  def footer
    <<EOS
<p align="right"><em>
Developed by <a href="http://www.sara.nl/">SARA</a> and <a href="http://www.gwdg.de/">GWDG</a><br/>
Sponsored by <a href="http://www.catchplus.nl/">CATCH+</a> and <a href="http://www.eudat.eu/">EUDAT</a>
</em></p></body></html>
EOS
  end # footer

end # class XHTML


# Base class of all resources in this web service.
class Resource


  include Rackful::Resource


  GLOBAL_LOCK_MUTEX = Mutex.new
  GLOBAL_LOCK_HASH = {}


=begin markdown
@param path [#to_s] The path of this resource. This is a `path-absolute` as
  defined in {http://tools.ietf.org/html/rfc3986#section-3.3 RFC3986, section 3.3}.
@see #path
@since 0.0.1
=end
  def initialize path
    self.path = path
  end


  def lock unlock = false
    self.class.lock self.path, unlock
  end


  def unlock
    self.lock true
  end


  def self.lock path, unlock
    GLOBAL_LOCK_MUTEX.synchronize do
      if unlock
        GLOBAL_LOCK_HASH.delete path
      elsif GLOBAL_LOCK_HASH[path]
        raise HTTP503ServiceUnavailable, 'Another client is modifying the resource.'
      else
        GLOBAL_LOCK_HASH[path] = true
      end
    end
  end


  def xhtml; ''; end


  add_serializer EPIC::XHTML
  add_serializer Rackful::JSON


end # class Resource


end # module EPIC

