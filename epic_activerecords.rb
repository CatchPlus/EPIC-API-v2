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
   
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter  => 'jdbcmysql',
  :database => 'epic',
  :hostname => 'localhost',
  :username => 'epic',
  :password => 'epic'
)
#ActiveRecord::Base.include_root_in_json = false
#ActiveRecord::Base.primary_key_prefix_type = :table_name_with_underscore

module EPIC  
  
class ActiveNA < ActiveRecord::Base
  self.table_name = :nas
end # class ActiveNA < ActiveRecord::Base

class ActiveHandleValue < ActiveRecord::Base
  self.table_name = :handles
  # The reason for the following statement is that database table +handles+
  # has a column named +type+, which is the default column name for inheritance
  # in ActiveRecord.
  self.inheritance_column = :active_type
end # class ActiveHandleValue < ActiveRecord::Base


end # module EPIC
