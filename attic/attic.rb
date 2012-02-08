require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => 'jdbcmysql',
  :database => "epic",
  :hostname => 'localhost',
  :username => 'epic',
  :password => 'epic'
)
ActiveRecord::Base.include_root_in_json = false
ActiveRecord::Base.primary_key_prefix_type = :table_name_with_underscore


module Epic
  
  
  class Na < ActiveRecord::Base
  end
  
  
  # This is a low level class that builds on ActiveRecord.
  class HandleRecord < ActiveRecord::Base
    set_table_name :epic_handles
    has_many :values,
      :class_name => 'ValueRecord',
      :foreign_key => :epic_handle_id,
      :primary_key => :epic_handle_id
    def serializable_hash(*args)
      retval = super(*args)
      if retval[:values]
        tmp = Hash.new
        retval[:values].each do |value|
          tmp[value['idx']] = value
        end
        retval[:values] = tmp
        #retval.delete :handle_values
      end
      retval
    end
  end
  
  
  # This is a low level class that builds on ActiveRecord.
  class ValueRecord < ActiveRecord::Base
    set_table_name :epic_values
    belongs_to :handle,
      :class_name => :HandleRecord,
      :foreign_key => :epic_handle_id,
      :primary_key => :epic_handle_id
    def serializable_hash(*args)
      retval = super(*args)
      if retval['epic_type']
        retval['type'] = retval['epic_type']
        retval.delete 'epic_type'
      end
      retval
    end
  end


end