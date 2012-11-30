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
require 'pp'

module EPIC
  class Profile < Resource
    # @api private
    # @return [Hash{ String(prefix) => Hash{ String(name) => Profile } }]
    def Profile.profiles
      @@profiles ||= {}
    end

    # @api private
    # @return [Hash{ String(name) => Profile }]
    def Profile.[] name
      profiles[name.to_s.downcase]
    end

    def Profile.inherited childclass
      profiles[childclass.name.split('::').last.downcase] = childclass
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
    def Profile.create( request, prefix, suffix, values )
      values
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
    def Profile.update( request, prefix, suffix, old_values, new_values )

      #       raise HTTP403Forbidden, "The operation is not allowed for the institute code."
      #           unless (USERS[request.env['REMOTE_USER']][:institute].upcase != request.GET['inst'].upcase)

      new_values
    end

    # This method must validate the deletion of a handle.
    # @param handle [Handle]
    # @return [void]
    # @raise [Rackful::HTTPStatus] if the deletion cannot pass.
    def Profile.delete( request, prefix, suffix, old_values ); end

    # A profile that uses UUIDs to guarantee the uniqueness of created Handles.
    class NoDelete < Profile
      def to_rackful
        {
          'Description' => 'This profile disables the deletion of all pids that match some regular expression.',
        }
      end
      
      def Profile.delete( request, prefix, suffix, old_values )
        message = "Enforcing nodelete-Profile. Deletion of handles is deactivated for this EPIC-API."
        LOGGER.warn(message)
        # TODO:
        # Error 405 Would be better. But this does not work yet. More Input  from Pieter needed.
        # raise Rackful::HTTP405MethodNotAllowed
        #
        raise Rackful::HTTP403Forbidden, message
      end

      # Override Methods like this
      #def Profile.update( request, prefix, suffix, old_values, new_values )
      #  new_values
      #end

    end # class NoDelete < Profile

    # A profile that uses an internal (technical) type ('INST') to share a prefix between institutes.
    #
    # The INST-Code is formatted in this way NNNN-XX
    # NNNN - is the Institute-Code at the Univerity of Goettingen
    # XX   - is a specific Code for sharing int INST among different users and/or entities within the insitute
    # NNNN and XX are separeted by a hyphen "-"
    #
    class GWDGPID < Profile
      def to_rackful
        {
          'Description' => 'This profile provides support for sharing a prefix between multiple institutes',
        }
      end

      def Profile.create( request, prefix, suffix, values )
        # Check if a insitute code is available in the config
        if USERS[request.env['REMOTE_USER']][:institute].nil?
          message = "Enforcing GWDGID-Profile. No Insitute-Code set for user #{request.env['REMOTE_USER']}. Request blocked with Error 403 - Forbidden."
          LOGGER.warn(message)
          raise Rackful::HTTP403Forbidden, message
        end
        
        # We can trust in the existance of a Institute code in the config. Now we create local variables.
        username = request.env['REMOTE_USER']
        insitute_code = USERS[request.env['REMOTE_USER']][:institute].upcase
        
        # Sanity-Checks of the Institute code should be done in EPIC::CheckConfig class.
        # Hence, no sanity checks of the institute-Codes are applied here.
        
        # Add institude code to the value to the value, that every handle has an INST type when this profile is enforced.
        pp values

        #    TODO:
        #    adding  :type = INST,  :parsed_data = inst  to  'values'

        #    TODO:
        #    some logging about the automatic changes made by the profile
        #    LOGGER.debug('added INST type with value' + inst + 'to the handle' + handle)
        values
      end

      def Profile.update( request, prefix, suffix, old_values, new_values )

        #        inst = USERS[request.env['REMOTE_USER']][:institute].upcase             # institute from users file

        # TODO:
        # ensure that the :type = INST has the value inst, otherwise forbidden

        #       raise HTTP403Forbidden, "The operation is not allowed for the institute code."
        #           unless (USERS[request.env['REMOTE_USER']][:institute].upcase != request.GET['inst'].upcase)

        #    TODO:
        #    some logging about the automatic changes made by the profile
        #    LOGGER.debug('added' + :type + 'type with value' + :xxxx + 'to the handle' + handle)
        LOGGER.warn('i was in profile')

        new_values
      end

    end # class NoDelete < Profile

  end # class Profile

end # module EPIC

