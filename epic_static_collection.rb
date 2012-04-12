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
   

module EPIC
  
  
class StaticCollection < Collection
  
  def initialize path
    super path
    case path
    when '/'
      @collection = [
        { :uri => 'handles/',   :description => 'all handles, indexed by prefix' },
        { :uri => 'profiles/',  :description => 'all profiles, indexed by prefix' },
        { :uri => 'templates/', :description => 'all templates, indexed by prefix' },
      ]
    else
      raise Djinn::HTTPStatus,
        "500 No static collection at #{path.unescape_path}"
    end
  end
  
  def each &block
    @collection.each &block
  end
  
end # class StaticCollection


end # EPIC
