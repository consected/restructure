@javascript
@call_log
Feature: Register an outgoing call
  As a user
  I want to enter details about an outgoing phone call either I made, or that was made by a rep
  In order that key data can be searched, the tracker maintains an accurate view of contact activities, and phone number status can be updated appropriately    
  * I should be able to select a phone number that I am logging actions against

Background:
  Given the user has logged in
  And the user is viewing the contact's record in Zeus

Scenario: the user indicates that he is making a call to a contact
  Given the contact has one or more phone number records
  When the user indicates he is calling one of the contact's phone numbers
  Then the user sees the call log for the contact

Scenario: While on a call a user needs to review and edit other information
  Given the user has indicated he is calling one of the contact's phone numbers
  And the user needs to edit or review other player information for the contact
  When the user views player information and tracker information
  Then the user selects specific items to edit
  Then the user can easily go back to the call log
