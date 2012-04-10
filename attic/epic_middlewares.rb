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
#--
   
require 'rack'

module EPIC
  
  
# Rack::Static always maps path '/' to some index document (+index.html+ by
# default). We don't want this, and this unwanted behavior is modified in this
# subclass of Rack::Static.
class Static < Rack::Static
  # Overrides Rack::Static#new: it sets +@index+ to nil unless some index was
  # explicitly defined in the +options+ argument.
  def initialize app, options = {}
    super app, options
    @index = nil unless options[:index]
  end
end # class Static


end # module EPIC
