=begin rdoc
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

The project is hosted at GitHub, as EPIC-API-v2[http://github.com/CatchPlus/EPIC-API-v2]

=== Links
* {Installation guide}[rdoc-ref:INSTALL.rdoc]
=end


require './config.rb'
require './secrets/users.rb'

require './epic_monkeypatches.rb'

require './epic_handle.rb'
require './epic_handles.rb'
require './epic_handlevalue.rb'
require './epic_nas.rb'
require './epic_directory.rb'

require 'singleton'


# The namespace for everything related to the EPIC Web Service.
module EPIC


# Like every Singleton, this class must be thread safe!
class ResourceFactory

  include Singleton

  def resource_cache
    Djinn::Request.current.env[:epic_resource_cache] ||= Hash.new
  end
  private :resource_cache

  def uncache path
    resource_cache.delete path.to_s.unslashify
  end

  def [] path
    path = path.to_s.unslashify
    cached = resource_cache[path]
    # Legal values for +cached+ are:
    # - Nil: the resource is not in cache
    # - False: resource was requested earlier, without success
    # - Djinn::Resource
    if ! cached.nil?
      # if +cached+ is +false+, we want to return +Nil+.
      return cached || nil
    end
    resource_cache[path] = case path # already unslashified!
    when ''
      StaticCollection.new '/', [ 'handles/', 'profiles/', 'templates/', 'batches/' ]
    when '/handles', '/profiles', '/templates', '/batches'
      NAs.new path.slashify
    when %r{\A/(batches)/\d+\z}
      StaticCollection.new path.to_s.slashify, []
    when %r{\A/handles/\d+\z}
      #StaticCollection.new path.to_s.slashify, ['hello/']
      Handles.new path.slashify
    when %r{\A/handles/\d+/[^/]+\z}
      Handle.new path
    when %r{\A/(templates|profiles)/\d+\z}
      Directory.new path.slashify
    else
      false
    end
  end

end # class ResourceFactory


end # module EPIC
