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

#require 'rubygems'
require 'sequel'
require 'singleton'

module EPIC

class DB

  include Singleton

  POOL = Sequel.connect(
    'jdbc:mysql://localhost/epic?user=epic&password=epic',
    :single_threaded => false
  )

  def initialize
    @all_nas = nil
  end

  def all_nas
    @all_nas ||= POOL[:nas].select(:na).collect do
      |row|
      row[:na]
    end
  end

  def all_handles prefix = nil
    ds = POOL[:handles].select(:handle).distinct
    if prefix
      ds = ds.filter( '`handle` LIKE ?', prefix + '/%' )
    end
    ds.collect { |row| row[:handle] }
  end

  def all_handle_values handle
    ds = POOL[:handles].where( :handle => handle ).all
  end

end

end
