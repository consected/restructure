@javascript
Feature: Register an outgoing call
  As a user
  I want to enter details about an outgoing phone call either I made, or that was made by a rep
  In order that key data can be searched, the tracker maintains an accurate view of contact activities, and phone number status can be updated appropriately    
  * I should be able to select a phone number that I am logging actions against

Background:
  Given the user has logged in
  And the user is viewing the contact's record in Zeus

Scenario: I indicate that I'm making a call to a contact
  Given the contact has one or more phone number records
  When I indicate that I am calling one of the contact's phone numbers
  Then I see the call log for the contact

Scenario: While on a call a user needs to review and edit other information
  Given I have indicated I am calling one of the contact's phone numbers
  And I need to edit or review other player information for the contact
  When I am still in the call log
  Then I can view all player information and related tracker information
  Then I can select specific items to edit
  Then I can easily go back to the call log and player view
