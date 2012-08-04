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


require 'config.rb'
require '../secrets/users.rb'

#require 'epic_monkeypatches.rb'

# Require all the resources served by this Resource Factory:
require 'epic_handle.rb'
require 'epic_handles.rb'
require 'epic_handlevalue.rb'
require 'epic_nas.rb'
require 'epic_directory.rb'
require 'epic_profile.rb'
require 'epic_template.rb'

require 'singleton'


=begin rdoc
@todo Documentation
=end
module EPIC


=begin
Resource Factory for all our ReSTful resources.

{Rackful::Server} requires a {Rackful::Server#resource_factory resource factory}. This
singleton class implements EPIC's resource factory.

Like every Singleton in a multi-threaded environment, this class must be thread safe!
@todo Move this class to a separate file? Not needed quite yet...
=end
class ResourceFactory


  include Singleton


=begin
Can be called by tainted resources, to be removed from the cache.
@return [self]
=end
  def uncache path
    resource_cache.delete path.to_s.unslashify
    self
  end


=begin
@param path [#to_s] the URI-encoded path to the resource.
@return [Resource, nil]
@see Rackful::Server#resource_factory for details
=end
  def [] path
    path = path.unslashify
    cached = resource_cache[path]
    # Legal values for +cached+ are:
    # - nil: the resource is not in cache
    # - false: resource was requested earlier, without success
    # - Rackful::Resource
    if ! cached.nil?
      # if +cached+ is +false+, we want to return +nil+.
      return cached || nil
    end
    resource_cache[path] = case path.unescape # already unslashified!
    when ''
      StaticCollection.new '/', [ 'handles/', 'profiles/', 'templates/', 'batches/' ]
    when '/handles', '/profiles', '/templates', '/batches'
      NAs.new path.slashify
    when %r{\A/(batches)/\d+\z}
      StaticCollection.new path.slashify, []
    when %r{\A/handles/\d+\z}
      #StaticCollection.new path.to_s.slashify, ['hello/']
      Handles.new path.slashify
    when %r{\A/handles/\d+/[^/]+\z}
      Handle.new path
    when %r{\A/(templates|profiles)/\d+\z}
      Directory.new path.slashify
    when %r{\A/profiles/\d+/\w[^/]+\z}
      Profile.new path
    # when %r{\A/templates/\d+/[^/]+\z}
      # Template.new path
    else
      false
    end
  end


  private


=begin
For performance, this {ResourceFactory} maintains a cache of
{EPIC::Resource Resources} it has produced earlier <em>within this same
request.</em>

Valid Hash values are:
[{Resource}] A cached resource
[false] The resource has been requested earlier, but wasn't found.
[nil] The resource hasn't been requested yet.
@return [Hash< unslashified_path => resource_object >]
=end
  def resource_cache
    Rackful::Request.current.env[:epic_resource_cache] ||= Hash.new
  end


end # class ResourceFactory


end # module EPIC
