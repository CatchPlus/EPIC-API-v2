require 'jsonpath'
require 'httparty'

class Connector
  include HTTParty
  default_timeout(9999999)
end


Given %r{^I use service "(.*?)"$} do |address|
  @req_base_uri = address
end

### pass the headers option with a hash of the headers you would like to include
When %r{^I accept (XML|JSON)$} do |type|
  @req_headers = {"Accept" => "application/#{type.downcase}"}
  @req_headers.merge!({"User-Agent" => "EPIC v2 API tester"})
end

When %r{^I (BASIC|DIGEST) authenticate as the user "([^"]*)" with the password "([^"]*)"$} do |type, user, pass|
  auth = {:username => user, :password => pass}
  type == "BASIC" ? @authorizing = {:basic_auth => auth } : @authorizing = {:digest_auth => auth }
end

When %r{^I request GET (.*)$} do |path|
  options = {:headers => @req_headers}
  options.merge!(@authorizing)
  @last_request = Connector.get(@req_base_uri + path, options)
end


Then %r{^the lowest prefix in the system is "([^\"]*)"$} do |response|
  answer = JSON.parse(@last_request.body)
  answer[0] == response
end

Then %r{^the handle should include the key "([^\"]*)"$} do |response|
  answer = JSON.parse(@last_request.body)
  answer[0][response].size() > 0
end

Then %r{^the http-return-code must be "([^\"]*)"$} do |status|
  raise "Expected HTTP-Status-Code was: #{status}. But I recieved #{@last_request.code}" unless @last_request.code == status.to_i
end

And %r{^I ignore all authentication} do
  @authorizing = { }
end

When %r{^I POST a handle in the format (JSON) of Type (URL) with the value "(.*?)" to "(.*?)"$} do |data_format, handle_type, handle_value, post_url_target|
  unless data_format.upcase == "JSON"
    raise "Other formats than JSON currently not supported"
  end
  unless handle_type == "URL"
    raise "Other types than URLS are currently not supported"
  end

  # Integrate Handling for other accepted formats here
  if data_format.upcase == "JSON"
    raw_data = '[{"type":"' + handle_type + '","parsed_data":"' + handle_value + '"},{"type":"INST","parsed_data":"1001"}]'
    @req_headers.merge!({"Content-Type" => "application/json"})
  end

  # Build the headers together to fire the post
  options = {:headers => @req_headers}
  options.merge!(@authorizing)
  options.merge!({:body => raw_data})
  @last_request = Connector.post(@req_base_uri + post_url_target, options)
  @handle_location = @last_request.headers['location']
end

Then %r{^the http\-header contains a field with the name "(.*?)"$} do |field_name|
  unless @handle_location.size() > 1
    raise "No http-header field: #{field_name} sent."
  end
  puts "Handle created/updated: #{@handle_location.split("/").last()}"
  true
end

When %r{^I POST test data to the previously created handle$} do
  raw_data = '[{"type":"URL","parsed_data":"http://example.net/impossible_update"},{"type":"INST","parsed_data":"1001"}]'
  @req_headers.merge!({"Content-Type" => "application/json"})
  options = {:headers => @req_headers}
    options.merge!(@authorizing)
    options.merge!({:body => raw_data})
    @last_request = Connector.post(@handle_location, options)
end

When %r{^I PUT a update of the previously created handle in the format (JSON) of Type (URL) with the value "(.*?)"$} do |data_format, handle_type, handle_value|
  unless data_format.upcase == "JSON"
    raise "Other formats than JSON currently not supported"
  end
  unless handle_type == "URL"
    raise "Other types than URLS are currently not supported"
  end
  # Integrate Handling for other accepted formats here
    if data_format.upcase == "JSON"
      raw_data = '[{"type":"' + handle_type + '","parsed_data":"' + handle_value + '"},{"type":"INST","parsed_data":"1001"}]'
      @req_headers.merge!({"Content-Type" => "application/json"})
    end
    options = {:headers => @req_headers}
    options.merge!(@authorizing)
    options.merge!({:body => raw_data})
    @last_request = Connector.put(@handle_location, options)
    @handle_location = @last_request.headers['location']
end

When %r{^I DELETE the previously created handle$} do
  @req_headers.merge!({"Content-Type" => "application/json"})
  options = {:headers => @req_headers}
    options.merge!(@authorizing)
    @last_request = Connector.delete(@handle_location, options)
end
