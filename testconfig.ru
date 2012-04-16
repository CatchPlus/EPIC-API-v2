#\ -p 8080
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
# This is a test to find out hat the ordering of use commands does:

require 'rack'


class MyApp

  def initialize( message )
    @message = message
  end

  def call environment
    [ 200, { 'Content-Type' => 'text/plain' }, [ @message ] ]
  end

end # class MyApp


class MyMiddleware

  def initialize( app, message )
    @app = app
    @message = message
  end

  def call environment
    retval = @app.call( environment )
    retval[2] = [ @message ]
    retval
  end

end # class MyMiddleware

use Rack::Auth::Digest::MD5, 'EPIC', '121212' do
  |username|
  if username.to_str === 'pieterb'
    'mooi123'
  else
    nil
  end
end
use MyMiddleware, 'Hallo wereld!'
use MyMiddleware, '¡Hola mundo!'
run MyApp.new( 'Hello world!' )
