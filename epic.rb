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
=begin rdoc
  
This is the source code documentation of the EPIC API version 2.

The project is hosted at GitHub, as
EPIC-API-v2[http://github.com/CatchPlus/EPIC-API-v2]

= License
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

= Links
* {Installation guide}[rdoc-ref:INSTALL.rdoc]
=end


require './config.rb'
require './secrets/users.rb'

require './epic_monkeypatches.rb'

require './epic_handle.rb'
require './epic_handles.rb'
require './epic_handlevalue.rb'
require './epic_nas.rb'

require 'singleton'


# The namespace for everything related to the EPIC Web Service.
module EPIC


# Like every Singleton, this class must be thread safe!
class ResourceFactory

  include Singleton

  def delete path
    path = path.to_s.unslashify
    Djinn::globals[:resource_cache].delete path
  end

  def << resource
    Djinn::globals[:resource_cache][resource.path] = resource
    self
  end

  def [] path
    path = path.to_s.unslashify
    Djinn::globals[:resource_cache] ||= {}
    retval = Djinn::globals[:resource_cache][path]
    if ! retval.nil?
      return retval || nil
    end
    case path.to_s.unslashify
    when ''
      StaticCollection.new '/', [ 'handles/', 'profiles/', 'templates/' ]
    when '/handles', '/profiles', '/templates'
      NAs.new path.slashify
    when %r{\A/handles/\d+\z}
      Handles.new path.slashify
    when %r{\A/handles/\d+/[^/]+\z}
      Handle.new path #.unslashify
    else
      false
    end
  end

end # class ResourceFactory


end # module EPIC
