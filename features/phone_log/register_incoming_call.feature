Feature: Register an incoming call
  As a user
  I want to enter details about a call I have received while using the app
  In order that the details can be tracked and searched

Background:
  Given the contact has a Master record
  And the user is viewing their record in Zeus
  And the user has details about the call they have received

Scenario: I indicate that I have received a call from a contact
  When I am viewing the contact’s record
  Then I indicate that I have received a call 

Scenario: I indicate the outcome of a received call
  Given I have indicated that I have received a call from a contact
  When I know the outcome of the call
  Then I record the outcome using one of the available options

Scenario: Capture free text notes
  Given I have indicated that I have received a call from a contact
  When I have notes to enter related to the call
  Then I record these notes in a free text field related to the call
