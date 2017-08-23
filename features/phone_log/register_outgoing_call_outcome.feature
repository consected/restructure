Feature: Register outcome of an outgoing call
  As a user
  I want to enter details about an outgoing phone call either I made, or that was made by a rep
  In order that activity can be searched and the tracker maintains an accurate view of contact activities 
  * I should be able to select a phone number that I am logging actions against
  * Actions related to a call can be rapidly selected
  * Other related tracker and player information should be visible without additional effort to find it
  * Other tracker activities can also be set without leaving the call log
  * Player information can be edited without leaving the call log
  * Where possible, tracker and phone record attributes can be updated through call log responses rather than needing to set them by hand (for example, bad phone number)
  * A user should be able to record call activity on behalf of a rep that is not a user of Zeus


Background:
  Given the contact has a Master record
  And the user is viewing their record in Zeus
  And the user has details about the call they made or was made by a rep
  And the user indicates that he or she is calling one of the contact’s phone numbers

Scenario: I speak to the contact about the reason for the call
  Given I have indicated I am calling one of the contact’s phone numbers
  When the contact answers the call and we speak about the reason for the call
  Then I record that I spoke to the contact successfully about the matter

Scenario: I speak to the contact but he does not want to talk about the required matter
  Given I have indicated I am calling one of the contact’s phone numbers
  When the contact answers the call but he does not want to speak about the matter now or in the future
  Then I record that I spoke to the contact but he did not want to discuss the matter

Scenario: I speak to the contact but they indicate they do not want to be called on any phone number in the future
  Given I have indicated I am calling one of the contact’s phone numbers
  When the contact answers the call and indicates he does not want to be called again
  Then I record that I spoke to the contact
  Then I record that he does not want to be called again

Scenario: I am requested not to call this number in the future
  Given I have indicated I am calling one of the contact’s phone numbers
  When I am informed not to call this number in the future
  Then I record this number to not be called in the future

Scenario: I am given an alternative number to call
  Given I have indicated I am calling one of the contact’s phone numbers
  When I am informed of an alternative number to call
  Then I record this new number to be used as the primary number
  Then if appropriate I record the current number to not be used in the future

Scenario: I speak to the contact and they ask me to call back
  Given I have indicated I am calling one of the contact’s phone numbers
  When the contact answers the call and asks me to call back
  Then I record that I spoke to the contact
  Then I record that a call-back was requested for a certain date and time

Scenario: I speak to the contact and he opts-out of the study
  Given I have indicated I am calling one of the contact’s phone numbers
  When I speak to the contact he tells me that he wants to opt of the study
  Then I record that the contact has opted-out of the study
  Then I see that the tracker record for the call and the opt-out are linked

Scenario: I leave a message
  Given I have indicated I am calling one of the contact’s phone numbers
  When the call connects to a voicemail service or I speak to somebody else and I leave a message
  Then I record that I left a message

Scenario: I leave a message and am asked to call back later
  Given I have indicated I am calling one of the contact’s phone numbers
  When I speak to the contact’s wife, I leave a message and they ask me to call back later
  Then I record that I left a message 
  Then I record that a call-back was requested for a certain date and time

Scenario: There is no answer
  Given I have indicated I am calling one of the contact’s phone numbers
  When there is no answer and no option to leave a voicemail or message
  Then I record that there was no answer (and no message was left)

Scenario: The call did not connect due to a bad number
  Given I have indicated I am calling one of the contact’s phone numbers
  When the call did not connect due to a bad number (does not exist, or does not belong to the contact)
  Then I record that the number was a bad number

Scenario: There was some other issue connecting
  Given I have indicated I am calling one of the contact’s phone numbers
  When the call did not connect successfully (or did, but the line was bad and retrying was unsuccessful) 
  Then I record that the call connected unsuccessfully

Scenario: Capture free text notes
  Given I have indicated I am calling one of the contact’s phone numbers
  When I have notes to enter related to the call
  Then I record these notes in a free text field related to the call

Scenario: A rep has taken notes to track a call and a user is entering them
  Given that a rep has taken notes to track a call similar to the way a user would
  And I am the user entering the details
  When I enter the call details
  Then I can select the rep’s name as the person making the call

Scenario: While on a call a user needs to review and edit other information
  Given I have indicated I am calling one of the contact’s phone numbers
  And I need to edit or review other player information
  When I am still in the call log
  Then I can view all player information and related tracker information
  Then I can select specific items to edit
  Then I can easily go back to the call log and player view
