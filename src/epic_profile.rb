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


class Profile < Resource


  # @api private
  # @return [Hash{ String(prefix) => Hash{ String(name) => Profile } }]
  def self.profiles
    @@profiles ||= {}
  end


  # @api private
  # @return [Hash{ String(name) => Profile }]
  def self.[] name
    self.profiles[name.to_s.downcase]
  end

  
  def self.inherited childclass
    self.profiles[childclass.name.split('::').last.downcase] = childclass
  end


  # This method validates the creation of a new handle.
  # 
  # The method can not only veto the creation of a handle, but also allow
  # handle creation, but with modified handle values.
  # @param [Rackful::Request] request
  # @param [String] prefix
  # @param [String] suffix
  # @param [(HandleValue)] values
  # @return [(HandleValue), nil] The (possibly modified) array of
  #   {HandleValue HandleValues} to put in the new {Handle}.
  # @raise [Rackful::HTTPStatus] if creation cannot pass.
  def self.create( request, prefix, suffix, values )
    nil
  end


  # @!method 
  # This method validates the update of an existing handle.
  # 
  # The method can not only veto the creation of a handle, but also allow
  # handle creation, but with modified handle values.
  # @param request [Rackful::Request]
  # @param prefix [String]
  # @param suffix [String]
  # @param old_values [(HandleValue)]
  # @param new_values [(HandleValue)]
  # @return [(HandleValue), nil] The (possibly modified) array of
  #   {HandleValue HandleValues} to put in the new {Handle}.
  # @raise [Rackful::HTTPStatus] if the update cannot pass.
  def self.update( request, prefix, suffix, old_values, new_values )
    nil
  end


  # This method must validate the deletion of a handle.
  # @param handle [Handle]
  # @return [void]
  # @raise [Rackful::HTTPStatus] if the deletion cannot pass.
  def self.delete( request, prefix, suffix, old_values ); end

  #Override Methods like this
  #def self.update( request, prefix, suffix, old_values, new_values )
  #  new_values
  #end


  # A profile that uses UUIDs to guarantee the uniqueness of created Handles.
  class NoDelete < Profile

    def to_rackful
      {
        'Description' => 'This profile disables the deletion of all pids that match some regular expression.',
      }
    end
    
    def self.delete( request, prefix, suffix, old_values )
      if NO_DELETE.include? prefix
        raise Rackful::HTTP403Forbidden, "PIDs with prefix #{prefix} cannot be deleted."
      end
    end

  end # class NoDelete < Profile


  # A profile that uses UUIDs to guarantee the uniqueness of created Handles.
  class GWDGOLDPIDAuth < Profile


    def to_rackful
      {
        'Description' => 'This profile restricts access to a subspace of the PID namespace.',
      }
    end


    # This method validates the creation of a new handle.
    # 
    # The method can not only veto the creation of a handle, but also allow
    # handle creation, but with modified handle values.
    # @param [Rackful::Request] request
    # @param [String] prefix
    # @param [String] suffix
    # @param [(HandleValue)] values
    # @return [(HandleValue), nil] The (possibly modified) array of
    #   {HandleValue HandleValues} to put in the new {Handle}.
    # @raise [Rackful::HTTPStatus] if creation cannot pass.
    def self.create( request, prefix, suffix, values )
      return nil unless GWDGPID_PREFIXES.include? prefix
      unless inst = USERS[request.env['REMOTE_USER']][:institute]
        raise Rackful::HTTP403Forbidden, "You don't have an institute code set."
      end
      inst.upcase!
      unless 0 == suffix.index("00-#{inst}-")
        raise Rackful::HTTP403Forbidden, "You can only create PIDs starting with #{prefix}/00-#{inst}-"
      end
      nil
    end


    # @!method 
    # This method validates the update of an existing handle.
    # 
    # The method can not only veto the creation of a handle, but also allow
    # handle creation, but with modified handle values.
    # @param request [Rackful::Request]
    # @param prefix [String]
    # @param suffix [String]
    # @param old_values [(HandleValue)]
    # @param new_values [(HandleValue)]
    # @return [(HandleValue), nil] The (possibly modified) array of
    #   {HandleValue HandleValues} to put in the new {Handle}.
    # @raise [Rackful::HTTPStatus] if the update cannot pass.
    def self.update( request, prefix, suffix, old_values, new_values )
      return nil unless GWDGPID_PREFIXES.include? prefix
      unless inst = USERS[request.env['REMOTE_USER']][:institute]
        raise Rackful::HTTP403Forbidden, "You don't have an institute code set."
      end
      inst.upcase!
      unless 0 == suffix.index("00-#{inst}-")
        raise Rackful::HTTP403Forbidden, "You can only update PIDs starting with #{prefix}/00-#{inst}-"
      end
      nil
    end


    # This method must validate the deletion of a handle.
    # @param handle [Handle]
    # @return [void]
    # @raise [Rackful::HTTPStatus] if the deletion cannot pass.
    def self.delete( request, prefix, suffix, old_values )
      return unless GWDGPID_PREFIXES.include? prefix
      unless inst = USERS[request.env['REMOTE_USER']][:institute]
        raise Rackful::HTTP403Forbidden, "You don't have an institute code set."
      end
      inst.upcase!
      unless 0 == suffix.index("00-#{inst}-")
        raise Rackful::HTTP403Forbidden, "You can only delete PIDs starting with #{prefix}/00-#{inst}-"
      end
    end


  end # class NoDelete < Profile


end # class Profile


end # module EPIC


