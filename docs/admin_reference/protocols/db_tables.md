# Tracker Protocol / Sub Process / Event in the Database

- Protocol: `ml_app.protocols`
- Sub Process: `ml_app.sub_processes`
- Event: `ml_app.protocol_events`

**NOTE:** Users may use the terms "status" for *sub process* and "method" for *event*, since this is how they are presented in the tracker UI.

Use a protocol, sub process or event lookup directly against a master record. For example, to find a player who has ever had a sub process of 144 or 24:

```
select distinct pi.* from player_infos pi inner join tracker_history th on th.master_id = pi.master_id
where sub_process in (144, 24);
```

Since each sub_process for a tracker / tracker history record belongs to a specific protocol, there is no need to explicitly state the protocol_id for simple matches.

Similarly, since each protocol_event for a tracker / tracker history record belongs to a specific sub_process and subsequently protocol, there is no need to explicitly state the protocol_id or sub_process_id for simple matches.

When using the attributes definer to create a search form, select the **type** as 'tracker protocol', 'tracker sub process or 'tracker protocol event'. The appropriate set of selections (tracker methods for example) will be automatically presented in a drop down or multiple selection field, based on the selection for **single or multiple values**.

Reference the user selection in SQL using the name of the field, prefixed with a colon. For example, when the attribute **name** `must_have_protocol` is entered, use:

```
select * from tracker_history where protocol_id in (:must_have_protocol)
```
