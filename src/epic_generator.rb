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

  ### A generator that creates GWDG-like strings and guarantees the uniqueness of created Handles.
  class GWDGPID < Generator

    def initialize *args
      super( *args )
      @parameters = {
        :inst => 'Mandatory: Institutecode, a string of UTF-8 encoded printable unicode characters to put at the beginning of the GWDGPID.',
        :prefix => 'Optional: a string of UTF-8 encoded printable unicode characters to put before the GWDGPID.',
        :suffix => 'Optional: a string of UTF-8 encoded printable unicode characters to put after the GWDGPID.'
      }
      @description = 'This generator creates GWDG-like strings and guarantees the uniqueness of created Handles.' ###(by using DB sequence).'
    end

###    /**
###     * Create Handle / PID string from components
###     * @param prefix the handle prefix, for example 42
###     * @param key the institute key, must be 4 uppercase letters or digits
###     * @param number the item number, at most 0xffffffffffL, not negative
###     * @param suffix the OPTIONAL suffix string, max MAX_SUFFIX_LEN uppercase
###     *   letters, digits or hyphens, or null (recommended) if no suffix used
###     * @return the converted value, for example 42/00-GWDG-0000-0000-D542-D,
###     * or null on error (check digit is ISO7064 for main 12 hex digits)
###     */
###    public static String makeHandle(String prefix, String key, long number, String suffix) {
###        // ISO7064 check digit, see e.g. http://modp.com/release/checkdigits/
###        // or             http://www.eurocode.org/guides/checkdig/english/
###        // or             http://www.collectionscanada.ca/iso/tc46sc9/isan/wg1n130.pdf
###        // or ISAN FAQ:   http://www.collectionscanada.ca/iso/tc46sc9/isan.htm
###        // or V-ISAN FAQ: http://www.collectionscanada.ca/iso/tc46sc9/v-isan.htm
###        if (number < 0 | number > 0xffffffffffffL)
###            return null; // number out of range
###        if ((key==null) || (!key.matches("^[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]$")))
###            return null; // bad institute key
###        if (suffix!=null && (suffix.length()>MAX_SUFFIX_LEN || !suffix.matches("^[A-Z0-9-]*$")))
###            return null; // invalid suffix
###        String hex = "00000000000" + Long.toHexString(number).toUpperCase();
###        hex = hex.substring(hex.length() - 12); // pad with 0s to 12 digits
###        StringBuffer handle = new StringBuffer(prefix);
###        handle.append("/00-");
###        handle.append(key).append('-');
###        handle.append(hex.substring(0, 4)).append('-');
###        handle.append(hex.substring(4, 8)).append('-');
###        handle.append(hex.substring(8)).append('-');
###        long check = 16;
###        for (int n = 11; n >= 0; n--) {           // check 12 lower digits
###            long digit = (number >> (4*n)) & 15;   // start at high digit...
###            digit = (digit + check) & 15;         // ...calculate modulo 16
###            if (digit == 0) digit = 16;           // ...but replace 0 by 16
###            digit = digit * 2;                    // ...now multiply by 2
###            if (digit >= 17) digit = digit - 17;        // ...and wrap to base 17
###            check = digit;
###        }
###        check = (17 - check) & 15;                // ...modulo 16
###        handle.append(Long.toHexString(check).toUpperCase()); // check digit
###        if (suffix!=null) { // suffix sanity checks already done above
###            handle.append('-');
###            handle.append(suffix);
###        }
###        return handle.toString();
###    } // makeHandle

    def generate request
      ### Institute code
      ### TODO: it should come from the AAI module and not as user input! Or the user input can be a hint, but has to be proven.
      inst = request.GET['inst'] + '-' || 'XXXX-'
#      inst.capitalize
      ### if inst? :nil
      
      ### Prefix
      ### TODO: should be a hex string? How long may it be?
      prefix = request.GET['prefix'] + '-' || ''
#      prefix.capitalize

      ### Suffix
      ### TODO: should be a hex string? How long may it be?
      suffix = '-' + request.GET['suffix'] || ''
#      suffix.capitalize

      ### Sequence number
      ### The sequence number is at most 0xffffffffffL, not negative
      ### Do we want own sequence numbers per institute like DB.instance.gwdgpidsequence('inst')?
      sequence = DB.instance.gwdgpidsequence 
      # .to_s(16).capitalize.rjust(12,'0')
      ### if sequence? :nil
#      if sequence < 0 or sequence > "FFFFFFFFFFFF".to_i(16)
#        nil
#      else
        ### Fixnum -> Hex: http://www.ruby-doc.org/core/classes/Fixnum.html#M001069
        ### Fixnum.to_s(base=16): Returns a string containing the representation of fix radix base (between 2 and 36).
        sequence = sequence.to_s(16).capitalize.rjust(12,'0') + '-'

      ### Checksum
      ### TODO: implement ISO7064 digit check
      checksum = 'X'
      
      '00-' + inst + prefix + sequence + checksum + suffix
    end

  end # class GWDGPID < Generator

end # class Generator

end # module EPIC

