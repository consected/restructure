# User Profile

**User Profile** definitions define the resources shown on the **user profile** page
to the current user.

## Resources list

A list of resources can be specified for the user profile page, for example

    contains: 
      resources:
        - user_preference
        - dynamic_model__user_details

If multiple *User Profile* definitions are available for the current app (or specified with no app type) then a full set of resources is created from the set of all the definitions, based on position order. A resource listed in multiple definitions is only
presented in the tab panel one time.

In addition to this definition, the user have at least a [user access control](../user_access_controls/0_introduction.md) (via user or role name) to read each resource, otherwise that resource will not be shown.
