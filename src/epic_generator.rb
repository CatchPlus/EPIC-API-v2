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

require 'epic_resource.rb'


module EPIC


class Generator < Resource

  # @api private
  # @return [Hash{ String(prefix) => Hash{ String(name) => Generator } }]
  def Generator.generators
    @@generators ||= {}
  end

  # @api private
  # @return [Hash{ String(name) => Generator }]
  def Generator.[] name
    generators[name.to_s.downcase]
  end
  
  def Generator.inherited klass
    generators[klass.name.split('::').last.downcase] = klass
  end
  
  # @return [Hash{Symbol => String(description}]
  attr_reader :parameters

  # @return [String]
  attr_reader :description
  
  def to_rackful
    { :description => description,
      :parameters => parameters }
  end

  # @!method generate(request)
  #   @param [Rackful::Request] request

  # A generator that uses UUIDs to guarantee the uniqueness of created Handles.
  class UUID < Generator

    def initialize *args
      super( *args )
      @parameters = {
        :prefix => 'Optional: a string of UTF-8 encoded printable unicode characters to put before the UUID.',
        :suffix => 'Optional: a string of UTF-8 encoded printable unicode characters to put after the UUID.'
      }
      @description = 'This generator uses UUIDs to guarantee the uniqueness of created Handles.'
    end

    def generate request
      prefix = request.GET['prefix'] || ''
      suffix = request.GET['suffix'] || ''
      prefix + DB.instance.uuid + suffix
    end

  end # class UUID < Generator

end # class Generator

end # module EPIC

