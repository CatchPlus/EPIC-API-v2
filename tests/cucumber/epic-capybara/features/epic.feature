Feature: EPIC API

	@mechanize
	Scenario: GET /handles/11022/12345678 (FAKE)
		Given I send a GET request for "http://wwwuser.gwdg.de/~tkalman/downloads/GET-123456.json"
		And the response status should be "200"
		And show me the response

	@mechanize
	Scenario Outline: user gets their details
	Given that I am a user
	Given I send and receive <format> 
	When I send a GET in <format> to "http://wwwuser.gwdg.de/~tkalman/downloads/GET-123456.json"
	Then show me the response

	Examples:
	|format|
	|JSON|
	|XML|




