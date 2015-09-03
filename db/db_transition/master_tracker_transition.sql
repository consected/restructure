set SEARCH_PATH=ml_app,ml_work;

/* Create the master list of msids - note this picks only the distinct msid entries,*/
insert into masters (msid, pro_id) select distinct msid, pro_id from ml_copy where msid is not null and accuracy_score <> -1 and accuracy_score <> 999;

/* Generate a full set of tracker records */
select *  into temp tracker_full from ml_work.tracker union select * from ml_work.tracker_history ;

/* Get rid of records not in the masters table) */
delete from tracker_full tf1 where not exists (select masters.msid from masters where masters.msid = tf1.msid);

/* add a serial column so we can match records in a moment */
alter table tracker_full add column id serial;
alter table tracker_full add column new_event_date timestamp;
alter table tracker_full add column protocol_id integer;
alter table tracker_full add column sub_process_id integer;
alter table tracker_full add column protocol_event_id integer;
alter table tracker_full add column protocol_name varchar;
alter table tracker_full add column sub_process_name varchar;
alter table tracker_full add column protocol_event_name varchar;

update tracker_full tf set 
    protocol_name = 
            (case when strpos(tf.event, 'General Awareness') = 1 then 'General Awareness' 
             when strpos(tf.event, 'R1') = 1 then 'R1' 
             when strpos(tf.event, 'Inquiry') = 1 then 'Inquiry' 
             else 'Q1' end ),
    sub_process_name = trim(c_method),
    protocol_event_name = trim(
        case when strpos(event, 'Q1 Mailing') = 1 then 'Q1 Mailing' 
        else event end
        ) || ' ' || outcome
;



/* Prepare the protocols / sub_processes / protocol_events */
select distinct ROW_NUMBER() over () "id", 
  protocol_name,
  1 "protocol_id", 
  sub_process_name, 
  2 "sub_process_id", 
  protocol_event_name
into temporary tracker_migration_lookup
from tracker_full group by protocol_name, sub_process_name, protocol_event_name, outcome;

/* Make a protocol_id number for each protocol name */
update tracker_migration_lookup set protocol_id = 1 where protocol_name = 'Q1';
update tracker_migration_lookup set protocol_id = 2 where protocol_name = 'R1';
update tracker_migration_lookup set protocol_id = 3 where protocol_name = 'General Awareness';
update tracker_migration_lookup set protocol_id = 4 where protocol_name = 'Inquiry';
 
/* create the remaining ids for sub_process and process_event */
select protocol_name, protocol_id, sub_process_name, first_value(id) over(partition by protocol_id, sub_process_name) "sub_process_id", protocol_event_name, id "event_id" into temp tracker_migration_lookup_ids from tracker_migration_lookup order by protocol_id, sub_process_name;

/* make the inserts into the lookup tables */
insert into protocols (id, name, created_at, updated_at) select distinct protocol_id, protocol_name, now(), now() from tracker_migration_lookup_ids;
insert into sub_processes(id, name, created_at, updated_at, protocol_id) select distinct sub_process_id, sub_process_name, now(), now(), protocol_id from tracker_migration_lookup_ids group by sub_process_name, sub_process_id, protocol_id;
insert into protocol_events(id, name, created_at, updated_at, sub_process_id) select  event_id, protocol_event_name, now(), now(), sub_process_id from tracker_migration_lookup_ids ;

/* force the sequences to update correctly */
SELECT setval('protocols_id_seq', (SELECT MAX(id) FROM protocols));
SELECT setval('sub_processes_id_seq', (SELECT MAX(id) FROM sub_processes));
SELECT setval('protocol_events_id_seq', (SELECT MAX(id) FROM protocol_events));






/* set the id  for protocol, sub process and protocol event in the temp tracker_full table */

/* get the protocol_id for the calculated protocol name*/
update tracker_full tf set protocol_id = (
    select distinct id from protocols 
        where protocols.name = tf.protocol_name
);

/* get the sub_process_id for the calculated sub process name */
update tracker_full tf set sub_process_id = (
    select distinct id from sub_processes 
        where sub_processes.name = tf.sub_process_name
        and tf.protocol_id = sub_processes.protocol_id
);

/* get the protocol_event_id for the calculated protocol event name */
update tracker_full tf set protocol_event_id = (
    select distinct id from protocol_events 
    where protocol_events.name = tf.protocol_event_name
    and tf.sub_process_id =  protocol_events.sub_process_id 
);


/* generate the event date for the new tracker - use the first one available from the following:  outcome_date, event_date, lastmod */
update tracker_full set new_event_date = case when outcome_date is not null then outcome_date when event_date is not null then event_date else lastmod end ;



/* pull the latest tracker entry for each msid / protocol pair */
select distinct on (msid, protocol_id) id, msid, new_event_date into temp tracker_latest from tracker_full order by msid, protocol_id, event_date desc, id;


/* now insert the latest records into tracker */
insert into ml_app.trackers 
(master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id)
select 
masters.id, tf.protocol_id, tf.event_date, now(), now(), tf.sub_process_id, tf.protocol_event_id
from tracker_full tf
inner join tracker_latest on tracker_latest.id = tf.id 
inner join masters on masters.msid = tracker_latest.msid;

/* Now go and add the history items that were not in the 'latest' set.
 * Add these, linking the tracker_id back to the matching tracker record created above that has a matching msid and protocol pair
 */

insert into ml_app.tracker_history 
(master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id, tracker_id)
select masters.id, tf.protocol_id, tf.event_date, now(), now(), tf.sub_process_id, tf.protocol_event_id, trackers.id
from tracker_full tf 
inner join masters on masters.msid = tf.msid
inner join trackers on trackers.master_id = masters.id and trackers.protocol_id = tf.protocol_id
where not exists ( select id from tracker_latest tl where tl.id = tf.id)
;




