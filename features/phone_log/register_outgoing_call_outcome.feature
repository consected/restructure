@javascript
@call_log
Feature: Register outcome of an outgoing call
  As a user
  I want to enter details about an outgoing phone call either I made, or that was made by a rep
  In order that activity can be searched and the tracker maintains an accurate view of contact activities 
  * I should be able to select a phone number that the user is logging actions against
  * Actions related to a call can be rapidly selected
  * Other related tracker and player information should be visible without additional effort to find it
  * Other tracker activities can also be set without leaving the call log
  * Player information can be edited without leaving the call log
  * Where possible, tracker and phone record attributes can be updated through call log responses rather than needing to set them by hand (for example, bad phone number)
  * A user should be able to record call activity on behalf of a rep that is not a user of Zeus


Background:
  Given the user is viewing the contact's record in Zeus
  And the user has details about the call they made or was made by a rep
  And the user has indicated he is calling one of the contact's phone numbers

Scenario: the user speaks to the contact about the reason for the call  
  When the contact answers a call from a user and they speak about the reason for the call
  Then the user records that he spoke to the contact successfully about the matter

Scenario: the user speaks to the contact but he does not want to talk about the required matter
  When the contact answers the call but he does not want to speak about the matter now or in the future
  Then the user records that he spoke to the contact but he did not want to discuss the matter

Scenario: the user speaks to the contact but they indicate they do not want to be called on any phone number in the future
  When the contact answers the call and indicates he does not want to be called again
  Then the user records that he spoke to the contact
  Then the user records that he does not want to be called again

Scenario: the user is requested not to call this number in the future
  When the user is informed not to call this number in the future
  Then the user records this number to not be called in the future

Scenario: the user is given an alternative number to call
  When the user is informed of an alternative number to call
  Then the user records this new number to be used as the primary number
  Then if appropriate the user records the current number to not be used in the future

Scenario: the user speaks to the contact and they ask me to call back
  When the contact answers the call and asks me to call back
  Then the user records that he spoke to the contact
  Then the user records that a call-back was requested for a certain date and time

Scenario: the user speaks to the contact and he opts-out of the study
  When the user speaks to the contact he tells me that he wants to opt of the study
  Then the user records that the contact has opted-out of the study
  Then the user sees that the tracker record for the call and the opt-out are linked

Scenario: he leaves a message
  When the call connects to a voicemail service or the user speaks to somebody else and he leaves a message
  Then the user records that I left a message

Scenario: he leaves a message and am asked to call back later
  When the user speaks to the contact’s wife, he leaves a message and they ask me to call back later
  Then the user records that I left a message 
  Then the user records that a call-back was requested for a certain date and time

Scenario: There is no answer
  When there is no answer and no option to leave a voicemail or message
  Then the user records that there was no answer (and no message was left)

Scenario: The call did not connect due to a bad number
  When the call did not connect due to a bad number (does not exist, or does not belong to the contact)
  Then the user records that the number was a bad number

Scenario: There was some other issue connecting
  When the call did not connect successfully (or did, but the line was bad and retrying was unsuccessful) 
  Then the user records that the call connected unsuccessfully

Scenario: Capture free text notes
  When the user has notes to enter related to the call
  Then the user records these notes in a free text field related to the call

Scenario: A rep has taken notes to track a call and a user is entering them
  Given that a rep has taken notes to track a call similar to the way a user would
  And the user is the user entering the details
  When the user enters the call details
  Then the user can select the rep’s name as the person making the call

Scenario: While on a call a user needs to review and edit other information
  And the user needs to edit or review other player information
  When the user is still in the call log
  Then the user can view all player information and related tracker information
  Then the user can select specific items to edit
  Then the user can easily go back to the call log
