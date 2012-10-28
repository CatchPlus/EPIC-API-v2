Feature: EPIC API
	Background:
	Given I use service "http://dariah-vm07.gwdg.de:8081/"
	When I accept JSON
	When I DIGEST authenticate as the user "tkalman" with the password "MyPaSsWoRd"

	Scenario: GET /handles/11022/123456-FAKED
		When I send a GET request for "~tkalman/downloads/GET-123456.json"
		Then the JSON response should have "idx"
		And the response status should be "200"
		And show me the response

	Scenario: GET /handles/11022/12345678 (FAKE)
		When I send a GET request for "http://wwwuser.gwdg.de/~tkalman/downloads/GET-123456.json"
		And the response status should be "200"
		And show me the response

	Scenario: GET /handles/11022/123456 (real)
		When I send2 a GET request for "http://dariah-vm07.gwdg.de:8081/handles/11022/123456"
		And show me the response

	Scenario: GET /handles/11022/123456 (real)
		When I send2 a GET request for "http://wwwuser.gwdg.de/~tkalman/downloads/GET-123456.json"
		And show me the response

	Scenario: hardcoded test (real)
		When I use hardcoded test
		And show me the response

