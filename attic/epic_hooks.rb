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

require 'singleton'
   
module EPIC
  
class Filters
  
  include Singleton
  
  def initialize
    super
    @filters = {}
  end

  def add_filter name, &block
    name = name.to_sym
    arity = block.arity
    or_more = arity < 0
    arity = -( arity + 1 ) if arity < 0
    raise 'Filters must accept at least 1 argument.' if 0 == arity
    @filters[name] ||= []
    @filters[name].push( {
      :arity    => arity,
      :or_more  => or_more,
      :block    => block
    } )
  end
  
  def call name, input, *args
    name = name.to_sym
    return input unless @filters[name]
    @filters[name].each do
      |filter|
      if filter[:arity] == args.length ||
         filter[:arity] <  args.length && filter[:or_more]
        input = filter[:block].call(input, *args)
      end
    end
    input
  end
  
end # class Filters
  
  
class Hooks
  
  include Singleton
  
  def initialize
    super
    @hooks = {}
  end

  def add_hook name, &block
    name = name.to_s
    arity = block.arity
    or_more = arity < 0
    arity = -( arity + 1 ) if arity < 0
    @hooks[name] ||= []
    @hooks[name].push( {
      :arity    => arity,
      :or_more  => or_more,
      :block    => block
    } )
  end
  
  def call name, *args
    name = name.to_s
    return input unless @hooks[name]
    @hooks[name].each do
      |hook|
      if hook[:arity] == args.length ||
         hook[:arity] <  args.length && hook[:or_more]
        hook[:block].call *args
      end
    end
  end
  
end # class Hooks
  
  
end # module EPIC