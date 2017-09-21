@javascript
@call_log
Feature: View call log
  As a user
  View details of calls made to, or received from players  
  * I should be able to select a phone number to view those calls related to that number

Background:
  Given the user has logged in
  And the user is viewing the contact's record in Zeus

Scenario: the user views the call log for a player
  Given the contact has one or more phone number records
  When the user indicates he wants to view the player's call log
  Then the user sees the call log for the contact

Scenario: the user views the call log for a specific phone number
  Given the contact has one or more phone number records
  And the user indicates he wants to view the player's call log
  When the user selects a phone number in the call log
  Then the user sees the call logs for the phone number selected