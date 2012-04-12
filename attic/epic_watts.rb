# Copyright �2011-2012 Pieter van Beek <pieterb@sara.nl>
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

require 'sinatra/base'
require 'sinatra/reloader'
require './epic_resources.rb'
require './epic_serialization.rb'


class String
  def slashify
    if '/' == self[-1,1]
      self.dup
    else
      self + "/"
    end
  end
  def slashify!
    if '/' == self[-1,1]
      self
    else
      self << "/"
    end
  end
  def unslashify
    if '/' == self[-1,1] && '/' != self
      self.chomp '/'
    else
      self.dup
    end
  end
  def unslashify!
    if '/' == self[-1,1] && '/' != self
      self.chomp! '/'
    else
      self
    end
  end
end


# The namespace for all of the webservice as developed by EPIC.
module EPIC

class Application < Sinatra::Base

  include EPIC::Serialization

  configure(:development) { register Sinatra::Reloader }
  configure(:development, :test, :production) { enable :logging }
  set :static, true
  set :default_encoding, 'UTF-8'

  def self.setup_resolver  
    @resolver = hdllib.HandleResolver.new
    sessionTracker = hdllib.ClientSessionTracker.new
    sessionTracker.setSessionSetupInfo( hdllib.SessionSetupInfo.new(nil) )
    @resolver.setSessionTracker(sessionTracker)
  end

  before do
    $logger = logger
  end

  error 406 do
    erb :'error406.html', :content_type => 'application/xhtml+xml'
  end

  get '/' do
    resources = Resources.new(
      '/',
      { :uri => 'handles/',   :description => 'All handles, by prefix' },
      { :uri => 'profiles/',  :description => 'All profiles, by prefix' },
      { :uri => 'templates/', :description => 'All templates, by prefix' },
    )
    some_erb :index, :locals => {
      :path => '/',
      :resources => resources
    }
  end

  get %r{^(/(handles|profiles|templates)/)$} do |path, what|
    description = "Collection of #{what}"
    resources = Na.nas.collect do |na|
      {
        :uri => na[5..-1] + '/',
        :name => na.dup,
        :description => description
      }
    end
    some_erb :index, :locals => {
      :path => path,
      :resources => resources
    }      
  end

  get '/handles/*/' do |prefix|
    #EPIC::Encoder.encode_suffixes(prefix, )
    resources = Suffixes.new( prefix ).collect do |suffix|
      {
        :uri => CGI.escape(suffix),
        :name => CGI.escapeHTML(prefix + '/' + suffix),
        :description => 'Handle'
      }
    end
    some_erb :index, :locals => {
      :path => "/handles/#{prefix}/",
      :resources => resources
    }
  end

  get '/handles/*/*' do |prefix, suffix|
    handle = Handle.new prefix, suffix
    return 404 if handle.empty?
    some_erb :handle, :locals => {
      :path => "/handles/#{prefix}/#{suffix}",
      :handle => handle
    }
  end

end

end # module EPIC

