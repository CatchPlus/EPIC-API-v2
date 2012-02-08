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
# This is the configuration file for the +rackup+ command.

require './epic.rb'
require 'rack/chunked'
require 'rack/reloader'

use Rack::Config do |env|
  req = Rack::Request.new env
  req.GET.each do |k, v|
    if %r{\A_http_(\w+)\z}i.match(k)
      env["HTTP_#{$1.upcase}"] = v.to_s
    end
  end
end
use Rack::Chunked
use Rack::Reloader, 1
use Rack::Sendfile
use EPIC::Static,
  :urls => ['/inc', '/favicon.ico', '/docs'],
  :root => 'public'
use Djinn::RelativeLocation
run Djinn::RESTServer.new(EPIC::ResourceFactory.instance)

#require './epic.rb'
#run Epic::Application
