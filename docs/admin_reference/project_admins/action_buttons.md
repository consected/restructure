# REDCap Project Transfer: Action Buttons

The information panel on the right-hand side of a REDCap project definition appear when the project has been set up.

## refresh

Simply refreshes the information in the admin panel to match the current state of the project and any actions that have been requested. The **Requests** tab will be updated to show any requests to the remote REDCap server made in the background or according to a timed schedule.

## retrieve records

Schedule an immediate transfer of all records from the REDCap project. After a little time, click the [refresh](#refresh) button then select the **Requests** tab to check that the retrieval has completed.

## retrieve user list

Fetch the list of users assigned to the REDCap project.

## retrieve data collection instruments list

Fetch the list of data collection instruments configured for the REDCap project.

## dump project archive to filestore

This pulls the full XML project archive and stores it as a file. This can be accessed in the **Files** tab.

## update dynamic model

In the configuration information that appears in the main section, a label **metadata and table fields** should show one of the following:

- REDCap fields match dynamic model table
- Dynamic model table has additional fields (pull will ignore them)

If this is not the case and a status appears highlighted red and ending with the text **(pull will fail)**, then action must be taken for a transfer to be successful. This typically happens if one of the **Options** `data_options:` settings has been changed, or fields have been added to the REDCap server's project definition.

Typically running the **update dynamic model** action is sufficient to rectify the situation and set up the new fields that are required.

## force reconfiguration

This action will perform an extensive reconfiguration of the definitions set locally. This may be destructive to configurations and should not be used unless an admin can validate the results. Typically this actions should not be required.
