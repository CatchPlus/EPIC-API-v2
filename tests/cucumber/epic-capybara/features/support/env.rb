
#require 'httparty'

### ----------
### json_spec
require 'json_spec/cucumber'

def last_json
  page.source
end
### ----------


### ----------
### api_steps:
require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support
require 'capybara/cucumber'

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css
###Capybara.default_driver = :rack_test
###Capybara.app = "make sure this isn't nil"
Capybara.app = "MyRackApp"
###Capybara.app_host = "http://localhost:8080"
Capybara.run_server = false

require 'cucumber/api_steps'
### ----------


### ----------
###Capybara-mechanize
###This gems makes it possible to use Capybara for (partially) remote testing. 
###It inherits most functionality from the RackTest driver and only uses Mechanize for remote requests.
###This gem is a Capybara extension.
#require 'capybara/mechanize/cucumber'
require 'capybara/mechanize'
Capybara.default_driver = :mechanize
### ----------


require 'logger'
agent = Mechanize.new { |a| a.log = Logger.new("mech.log") }


### to define last_json if you are using something a gem like rest-client or http-party which returns a ‘response’ object then, in the step that makes the call capture the response along these lines
###@last_response = RestClient.post(url, request_body, :content_type => ‘application/json’)
### Then wherever you are maintaining world extensions (usually a file under features\support) add something like the following
#module JSONSpecInterface
#def last_json
#@last_response.body
#end
#end
#World(JSONSpecInterface)