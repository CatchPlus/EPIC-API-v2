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

# This file contains all {monkey patches}[http://en.wikipedia.org/wiki/Monkey_patch]
# in the code base. Because monkey patches are, in general, a bad idea, I
# chose to at least isolate them in a single file, so that it remains
# obvious what monkey patches exist.

require 'rack'

class String
  def slashify
    if '/' == self[-1,1]
      self.dup
    else
      self + "/"
    end
  end
  def unslashify
    if '/' == self[-1,1]
      self.chomp '/'
    else
      self.dup
    end
  end
  # An alias for Rack::Utils.escape_html
  def escape_html; Rack::Utils.escape_html(self); end
  # An alias for Rack::Utils.escape_path
  def escape_path; Rack::Utils.escape_path self; end
  # An alias for Rack::Utils.unescape
  def unescape_path( encoding = Encoding::UTF_8 ); Rack::Utils.unescape self, encoding; end
end
