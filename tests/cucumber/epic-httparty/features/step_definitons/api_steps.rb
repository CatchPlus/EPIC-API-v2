require 'jsonpath'
#require 'test/unit'

#@options2 = Hash.new

### recursively merges 2 hashes (of HTTParty options)
def optmerge!(opt_hash)
	merge!(opt_hash) do |key, oldval, newval|
		oldval.class == self.class ? oldval.optmerge!(newval) : newval
	end
end


Given /^I use service "(.*?)"$/ do |address|
	@req_base_uri = address
end

### pass the headers option with a hash of the headers you would like to include
When /^I accept (XML|JSON)$/ do |type|
  @req_headers = {"Accept" => "application/#{type.downcase}"}
  #@options2 = { :headers => {"Accept" => "application/#{type.downcase}"}
	@options2 = {:headers => {"User-Agent" => "Tibor's API tester"}}
#  @options2.optmerge!({:headers => {"Accept" => "application/#{type.downcase}"}})
  @req_headers.merge!({"User-Agent" => "Tibor's API tester"})
#  options2.merge!({ :headers => @header })
#puts @headers
#puts @options2
end

When /^I (BASIC|DIGEST) authenticate as the user "([^"]*)" with the password "([^"]*)"$/ do |type, user, pass|
    @req_auth = {:username => user, :password => pass}
	authtype = type.downcase + '_auth'	### basic_auth, digest_auth
	###@options = { :headers => { :{authtype.downcase}_auth => @auth }
    ###@blah = HTTParty.get("http://xxx.com/rest.json", :basic_auth => auth)
    ###@blah = HTTParty.get("http://xxx.com/rest.json", :digest_auth => auth)
#    options2.merge!({ :#{authtype} => @auth })
    ###.post('/url/update.json', options)
end	

When /^I send a (GET|POST|PUT|DELETE) request (?:for|to) "([^"]*)"(?: with the following:)?$/ do |*args|
  request_type = args.shift
  request_type.downcase!
  req_path = args.shift
  req_body = args.shift
#options = {
#  :body => {
#    :pear => { # your resource
#      :foo => '123', # your columns/data
#      :bar => 'second',
#    }
#  }
#}
#.post('/pears.xml', options)
###  options = { :headers => @header, :digest_auth => @auth, :body => @body }
######  options[:query] = options[:query].inject({}) { |h, q| h[q[0].to_s.camelize] = q[1]; h }
  options = { :headers => @req_headers, :digest_auth => @req_auth, :body => @req_body }
  puts options.inspect
###  a = HTTParty.get(path, options)
@last_response = HTTParty.get(req_path, options)
    	###a = HTTParty.#{request_type.downcase}(path, options)
end


When /^I use hardcoded test$/ do |*args|
	@last_response = HTTParty.get("http://dariah-vm07.gwdg.de:8081/handles/11022/123456", :headers => {"Accept" => "application/json"}, :digest_auth => {:username => 'tkalman', :password => 'MyPaSsWoRd'})
end

Then /^show3 me the response$/ do
	###One of the coolest features of HTTParty is that it automatically parses JSON and XML responses, 
	###based on the Content-Type of the response, so as soon as your response comes back 
	###it’s ready for you to work with it:
	###puts response[0]["number"]
###  json_response = JSON.parse(@last_response.to_s)
###  puts JSON.pretty_generate(@last_response.to_s)
	puts @last_response.to_s
end

Then /^the response3 status should be "([^"]*)"$/ do |expected_status|
	### http://blog.teamtreehouse.com/its-time-to-httparty
	### The object returned from HTTParty.get is an HTTParty::Response object containing 
	### the JSON that was returned from the site, along with its headers and other methods 
	### relating to the HTTP protocol, like the protocol version.

#puts @last_response.headers.inspect
puts @last_response.response.inspect
puts @last_response.response.code.inspect
	actual_status = @last_response.response.code.to_i
puts actual_status.inspect

	if actual_status != expected_status
		assert_equal actual_status, expected_status
	end

#Then 'the JSON response should be:' do |json|
#  expected = JSON.parse(json)
#  actual = JSON.parse(page.driver.response.body)

#  if page.respond_to?(:should)
#    actual.should == expected
#  else
#    assert_equal actual, response
#  end
#end

#  if @last_response.response.code? :should
#    @last_response.response.code.should == res_status.to_i
#  else
#    assert_equal status.to_i, @last_response.response.code
#  end
end




### -------------------------------------------------------------------------------------
Given /^I send and accept (XML|JSON)$/ do |type|
  page.driver.header 'Accept', "application/#{type.downcase}"
  page.driver.header 'Content-Type', "application/#{type.downcase}"
end

Given /^I send and accept HTML$/ do
  page.driver.header 'Accept', "text/html"
  page.driver.header 'Content-Type', "application/x-www-form-urlencoded"
end

When /^I authenticate as the user "([^"]*)" with the password "([^"]*)"$/ do |user, pass|
  if page.driver.respond_to?(:basic_auth)
    page.driver.basic_auth(user, pass)
  elsif page.driver.respond_to?(:basic_authorize)
    page.driver.basic_authorize(user, pass)
  elsif page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:basic_authorize)
    page.driver.browser.basic_authorize(user, pass)
  elsif page.driver.respond_to?(:authorize)
    page.driver.authorize(user, pass)
  else
    raise "Can't figure out how to log in with the current driver!"
  end
end



When /^I send2 a (GET|POST|PUT|DELETE) request (?:for|to) "([^"]*)"(?: with the following:)?$/ do |*args|
  request_type = args.shift
  path = args.shift
  body = args.shift
  if body.present?
    page.driver.send(request_type.downcase.to_sym, path, body)
  else
    page.driver.send(request_type.downcase.to_sym, path)
  end
end

Then /^show2 me the response$/ do
  json_response = JSON.parse(page.driver.response)
  puts JSON.pretty_generate(json_response)
end

Then /^the response2 status should be "([^"]*)"$/ do |status|
  if page.respond_to? :should
    page.driver.response.status.should == status.to_i
  else
    assert_equal status.to_i, page.driver.response.status
  end
end

Then /^the JSON response should (not)?\s?have "([^"]*)" with the text "([^"]*)"$/ do |negative, json_path, text|
  json    = JSON.parse(page.driver.response.body)
  results = JsonPath.new(json_path).on(json).to_a.map(&:to_s)
  if page.respond_to?(:should)
    if negative.present?
      results.should_not include(text)
    else
      results.should include(text)
    end
  else
    if negative.present?
      assert !results.include?(text)
    else
      assert results.include?(text)
    end
  end
end

Then /^the XML response should have "([^"]*)" with the text "([^"]*)"$/ do |xpath, text|
  parsed_response = Nokogiri::XML(page.body)
  elements = parsed_response.xpath(xpath)
  if page.respond_to?(:should)
    elements.should_not be_empty, "could not find #{xpath} in:\n#{page.body}"
    elements.find { |e| e.text == text }.should_not be_nil, "found elements but could not find #{text} in:\n#{elements.inspect}"
  else
    assert !elements.empty?, "could not find #{xpath} in:\n#{last_response.body}"
    assert elements.find { |e| e.text == text }, "found elements but could not find #{text} in:\n#{elements.inspect}"
  end
end

Then 'the JSON response should be:' do |json|
  expected = JSON.parse(json)
  actual = JSON.parse(page.driver.response.body)

  if page.respond_to?(:should)
    actual.should == expected
  else
    assert_equal actual, response
  end
end

Then /^the JSON response should have "([^"]*)" with a length of (\d+)$/ do |json_path, length|
  json = JSON.parse(page.driver.response.body)
  results = JsonPath.new(json_path).on(json)
  if page.respond_to?(:should)
    results.first.length.should == length.to_i
  else
    assert_equal length.to_i, results.first.length
  end
end
