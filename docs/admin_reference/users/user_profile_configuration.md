# User Profile Configuration

## Creating User Profiles

Only application _admins_ have the ability to create _user_ profiles. This is performed through the **Usernames and Passwords** administration panel. A new _user_ is created by submitting his or her email address. This action creates a random password, which is displayed to the _admin_ one time only and a simple document containing this information for the end user. The _admin_ is responsible for delivering this document to the end-user securely.

## Resetting User Passwords

Only _admins_ have the ability to reset a _user’s_ password if the _user_ is unable to login for some reason. This is performed through the application **Usernames and Passwords** administration panel. 

To reset a password, the _admin_ selects the _user_ from a list, edits the profile and selects the option: **generate new password**. Similar to creating a _user_ initially, the _admin_ is displayed a new random password for the _user _one time only and a simple document containing this information for the end user. The _admin_ is responsible for delivering this document to the end-user securely.

## Two-Factor Authentication (2FA)

Since version 7.0.85 the Athena apps require users to login using a two-factor authentication token in addition to username and password.

Two-Factor Authentication (2FA) is implemented by requiring the entry of a time-based token at login time. Commonly available authenticator smartphone apps are used by users to generate this token. Users will see this token referred to in the app as a **one-time token**.

Each _user _and _admin_ profile has a unique _2FA_ secret generated when a new profile is created, or if  reset by the administrator. The administrator does not get to see this secret, and it is stored in the database in an encrypted format.

The first time that a user logs in after creation of a profile or reset of the _2FA_ secret they are presented with a two-factor authentication configuration page. This page provides a convenient QR Code barcode used by smartphone authenticator apps to set up a profile for future token generation. Once a token is entered and validated this first time the secret can not be viewed again and must be reset by an administrator if the user is no longer able to use it.  To reset the secret, the admin edits the _user_ profile and selects the option: **Reset two factor auth**

## Changing User Passwords

A _user_ has the ability to change her own password. After logging in to the application, an option to change the password is made available in the menu. This requires both the current and new _user_ passwords to be entered.

Similarly, an _admin_ has the ability to change his own password. After logging in to the application management panel an option to change the password is made available. This requires both the current and new _admin_ passwords to be entered.

## Password Complexity

Passwords, whether automatically generated by an _admin_, or changed by a _user_, must meet the following rules:

* Minimum characters: 10
* Maximum characters: 72
* Does not match email address
* Calculates an [entropy calculation](http://cubicspot.blogspot.com/2011/11/how-to-calculate-password-strength.html) based on the password complexity, reduced for
  * Repeated characters
  * Words appearing in Linux dictionary words file
  * Words in a list of common passwords
  * Words appearing in any part of the email address
  * Minimum entropy score: 24



## Disabling User Access

A _user_ profile can be disabled by an _admin_ through the **Usernames and Passwords** admin panel. This action prevents a _user_ from logging in or attempting to change her password.

In the future, an _admin _can re-enable a _user_ profile if needed.

There is no way to delete a _user_ profile from the application. This ensures that all data records created or updated by a _user_ retain a reference to the profile responsible for editing them.