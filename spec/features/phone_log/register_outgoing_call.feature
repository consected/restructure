Feature: Register an outgoing call
  As a user
  I want to enter details about an outgoing phone call either I made, or that was made by a rep
  In order that key data can be searched, the tracker maintains an accurate view of contact activities, and phone number status can be updated appropriately    
  * I should be able to select a phone number that I am logging actions against

Background:
  Given the contact has a Master record
  And the user is viewing their record in Zeus
  And the user has details about the call they made or was made by a rep

Scenario: I indicate that I’m making a call to a contact
  Given the contact has one or more phone number records
  When I am viewing the contact’s record
  Then I indicate that I am calling one of the contact’s phone numbers

Scenario: While on a call a user needs to review and edit other information
  Given I have indicated I am calling one of the contact’s phone numbers
  And I need to edit or review other player information for the contact
  When I am still in the call log
  Then I can view all player information and related tracker information
  Then I can select specific items to edit
  Then I can easily go back to the call log and player view
