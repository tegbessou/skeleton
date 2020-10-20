Feature: 
  In order to visit the home page
  As a User
  I want to see home page
  
  @read-only
  Scenario: As a User I want to see the home page
    Given I go to "/"
    Then the response status code should be 200
    And the response should contain "Welcome on Skeleton!"