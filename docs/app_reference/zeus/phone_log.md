# Zeus Phone Log

## Logging phone calls

Phone logs are accessible directly from the standard master information view. There are two ways to access the phone logs for a player.

![image](images/image26.png)

The **phone log** button at the top of the record is one way to view the phone log.

![image](images/image12.png)

The icon ![image](images/image25.png) on each player **Phone** record provides a direct link to the phone log. This also has the effect of highlighting phone log records associated with that phone number.

![image](images/image9.png)

In this first example, an empty phone log is displayed, above the **Tracker**information block. On the left hand side, a block shows the available phone numbers for the player (in this example, just one.) These phone numbers match the list of phone numbers in the standard **player contacts** list, filtering out the the email address records.

![image](images/image17.png)

Clicking the phone number in the phone log list highlights the block and any phone log records associated with it. Importantly, it also shows the **add log** button. Clicking this button opens an edit form to create a phone log record associated with the selected phone number.

![image](images/image15.png)

In this example, we change the default selections to **Select result** indicating we _Left Voicemail_, and **Select next step** to _Call Back_, with **Follow up when** on 1/18/2018.

It is possible to enter notes about the call, or details as reminders to help with a future call.

![image](images/image20.png)

The result is a phone log record showing the associated phone number and the entered information.

![image](images/image24.png)

Now we add a second phone log record. This time we indicate that the call connected, more information was requested and add a follow up date in the future. Note that if necessary, the **Called when** date can be changed from the default (today) to a date in the past.

![image](images/image27.png)

The result is the two phone log records, displaying the most recent first based on the entered **Called when** date.

![image](images/image1.png)

## Recording resolutions

If a phone call resolves an issue and does not need additional follow-ups, then it is simply a matter of selecting the next step to be **Complete**. But what happens if the last phone log we added requires a follow up (in our example because more information was requested) and we resolve the issue through some other channel (such as email)? It clearly doesn’t make sense to add a phone log record associated with a specific phone number, when the contact was through email.

To manage this, we have the concept of a **general log**. This is a simplified version of a phone log record that is not tied to any phone number. To add one, click the **+ General log** button that appears below the phone number blocks. This opens a general log form.

![image](images/image23.png)

After creation of the general log item, having selected the next step as **Complete**, the result appears with all three log records, the most recent showing that the chain is complete.

![image](images/image11.png)

Additional phone log records can be added in the future to handle new calls, issues and requests.

## Search for overdue follow-ups

To see the importance of marking phone logs with a resolution, let’s search for phone log records where a follow-up is overdue. Pick the **Phone Log Follow Up** search and run it with default criteria (your own phone logs, where the follow up was set before today).

![image](images/image2.png)

The results returned are for all master records having a follow-up set that has not been resolved with a later phone log or general log record marked as complete.

Checking one of the records, we see the phone log indeed has the final item indicating a _Call Back_ is required, and the **follow up when** date is in the past.

![image](images/image7.png)

Imagine that we use this as a prompt to contact the player. Rather than phoning, in this case we send an email and get a response that resolves the issue. We add a general log marking the **Select next step** as _Complete_.

![image](images/image18.png)

Note that if we had called the player rather than emailing, we would just add a standard phone log record (with **Select next step** as _Complete_)__rather than general log record. In terms of marking the current chain of calls as resolved, both types of log produce the same result.

The full phone log now appears like this:

![image](images/image3.png)

A renewed search for ‘open’ phone log follow-ups no longer shows this player.

![image](images/image2.png)

## Managing phone numbers within the phone log

While making a call, imagine that the player tells you that he would prefer you not use this phone number in the future. Within the phone log edit form the field **Set related player contact rank** can be changed.

![image](images/image29.png)

When the phone log record is saved, the rank on the related phone number is automatically changed to the selected value.

![image](images/image30.png)

Another possibility while making a call is that the player tells you a new phone number he prefers you use in the future. Underneath the phone number blocks click the button **+ Player contact record**.

The standard player contact **Phone** edit form appears, allowing a new phone number to be entered.

![image](images/image14.png)

When saved, the new phone number will appear as a new block. If the _rank_ was set to **10 - primary** then the existing primary phone number will be demoted to **5 - secondary**, consistent with the standard player contact functionality.

![image](images/image5.png)

## Tracker records for phone logs

Viewing the full tracker list, we see each of the phone log records appears as an update. When spread over time where other activity is being tracked, this view provides the full context for phone logs and other tracker activities.

![image](images/image19.png)

Each entry in the tracker has a paperclip icon next to it. When clicked, this links back to the associated phone log record, highlighting the appropriate block, making it easy to see the full view of the logged item.

![image](images/image16.png)

## Linking a phone log record to a _protocol_

It is possible to link a phone log record to a specific protocol, allowing the reason for a call to be tracked. In the phone log form, select the appropriate **Protocol** field value.

When saved, the tracker panel shows an entry **Q1**| **Activity**|**Phone Log**, with a paperclip link

![image](images/image8.png)

If additional tracker records are needed, it is possible to relate them to the associated phone log record by clicking the button **+ Related Tracker record**. This presents the standard tracker form, pre-populated with the phone log protocol (if selected). You can the select the _Status_ and _Method_ and if necessary update the _Event date_.

![image](images/image28.png)

The new tracker record is created, and the paperclip icon links back to the appropriate phone log record, opening the phone log if it is not visible and highlighting the record.

![image](images/image6.png)

From a phone log record it is also easy to see all the **Related tracker items** by clicking the link of the same name.

This drops down a list, where the icon on each entry  links to the tracker record in the tracker panel.

![image](images/image31.png)

In this way it is possible to see all the related tracker items in the context of the phone log, and within the broader context of the tracker, all the items related to the phone log.

## Tagging phone logs

Phone log records can be tagged using configurable tags. Tags can help with recording the outcome of a specific call in more detail. The **opt-out** options shown in this example provide a structured way to record this result, while helping users avoid inadvertently entering health information in the **notes**.

![image](images/image21.png)

Multiple tags can be selected if necessary, so many different tag configurations can be made related to different outcomes or other recordkeeping requirements.

![image](images/image10.png)

## Log phone calls made by non-Zeus representatives

It is possible to create phone log records that were made or received by FPHS representatives that are not users of Zeus. Simply add a phone log record as normal, then **Select who** made or received the call.

![image](images/image32.png)

The result is a record showing the selected person.

![image](images/image13.png)

In the phone log search forms, the user or person can be used to search or sort results.

It is necessary for the names of representatives to be configured by a Zeus administrator in the admin panel for **General Selections**.

## Review phone logs

In addition to searching for phone logs requiring a follow-up, we can also search for all phone log records within a date range.

Go to the **Reports** page and find the **Phone Logs** report. Enter the date range and run the report as a **table**.

A full list of phone log records are generated. They can be sorted by clicking any of the column headers.

![image](images/image33.png)

The reports are configurable. If there are specific requirements for new fields or different values, ask a Zeus administrator.
