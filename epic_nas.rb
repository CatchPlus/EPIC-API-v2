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

require 'epic_collection.rb'

module EPIC

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
