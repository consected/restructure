# User Login, Lock-Out and Timeout

## User Login

A user login form is presented for any application page that a person visits if not already logged in. The _user_ login form requests entry of the _user’s_ **Email**, **Password** and **One-Time Token**. The password field is a standard HTML password input field, obscuring the entry according to the standards of the web-browser used. 

There is no option provided by the application to “remember me”, ensuring that an email address, password and one-time token must always be entered. The login form fields do not prevent the use of password management tools, either provided by the browser or through third-party add-ons such as LastPass, so for convenience a _user_ may make use of these to generate and remember complex passwords.

## Login Lock-Out

When attempting to login, a _user_ or _admin_ must enter a correct password and one-time token for their email within a defined number of attempts.

* **3 attempts**  *(server settings allow configuration)*

If the user fails to login with correct credentials within the number of allowed attempts, the account is locked for a period of **1 hour**
*(server settings allow configuration)*, after which time the counter is reset and the user can attempt to login again.

## Session Timeout

A _user_ session will timeout if there is inactivity (any request that makes a request to the application server on a page that requires a _user_ session) for a length of time.

The default timeout is **30 minutes** *(based on server settings)*. Specific app configurations may set different timeout periods.

After timeout, all tabs or windows associated with the _user’s_ session will automatically redirect to the _user_ login page to avoid unintentionally leaving application data on screen indefinitely.

