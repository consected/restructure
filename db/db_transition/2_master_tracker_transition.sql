set SEARCH_PATH=ml_app,ml_work;

insert into admins (email) values 'auto-admin';


drop table tracker_full;
drop table tracker_migration_lookup;
drop table tracker_migration_lookup_ids;
drop table tracker_latest;
drop table tracker_hist_only;
drop table p_list;

delete from ml_app.tracker_history;
delete from ml_app.trackers;
delete from ml_app.protocol_events;
delete from ml_app.sub_processes;
delete from ml_app.protocols;




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
alter table tracker_full add column user_id integer;

update tracker_full tf set 
    protocol_name = 
        case 
            when strpos(tf.event, 'General Awareness') = 1 then 'General Awareness'          
            when event is NULL then 'Study'
            else 'Q1' 
        end
    ,
    sub_process_name = 
        case
            when event is NULL then 'Info'
            when strpos(event, 'General Awareness') = 1 then 
                case 
                    when outcome is NULL then 'Sent'
                    when trim(outcome) = 'Active' then 'Sent'
                    when trim(outcome) = 'Pending' then 'Sent'
                    when trim(outcome) = 'Opt Out' then 'Unsubscribe'
                    when trim(outcome) = 'Bounced' then 'Bounced'
                    else trim(outcome)
                end
            else
                case 
                    when trim(event) = 'Inquiry' then 'Inquiry'

                    when trim(outcome) = 'Opt Out' then 'Opt Out'
                    when trim(outcome) = 'Bounced' then 'Bounced'
                    when trim(outcome) = 'Complete' then 'Complete'
                    when trim(outcome) = 'Active' then 'Sent'
                    when trim(outcome) = 'Pending' then 'Sent'
                    when outcome IS NULL then 'Sent'
                    else trim(outcome)
                end
        end
    ,
    protocol_event_name = 
        case 
            when event is NULL then NULL
            when strpos(event, 'General Awareness') = 1 then 
                case 
                    when outcome IS NULL or trim(outcome) = 'Opt Out' then NULL                    
                    else trim(c_method)
                end
            else
                case                     
                    when trim(outcome) = 'Opt Out' then NULL
                    when trim(event) = 'Inquiry' AND trim(outcome) =  'Staff-message' then  trim(c_method) || ' from Staff'
                    when trim(event) = 'Inquiry' AND trim(outcome) =  'Player-message' then  trim(c_method) || ' from Player'    
                    when trim(event) = 'Inquiry' AND trim(outcome) =  'Complete' then  'Inquiry Complete'
                    when trim(event) = 'Inquiry' then 'Inquiry ' || trim(outcome)
                    when trim(event) = 'Prenotification' then 'Prenotification' 
                    when trim(event) = 'R1' then 'Reminder - Mail' 
                    when trim(event) = 'Thank You' then 'Thank You' 
                    when trim(c_method) = 'Scantron' OR trim(c_method) = 'Mail' then 'Scantron'
                    when trim(c_method) = 'REDCap' OR trim(c_method) = 'Email' then 'REDCap'
                    when outcome IS NULL OR c_method IS NULL then NULL
                    
                    else trim(c_method)                    
            end
        end
    
;

/* set the new user id based on the changedby user info */
update tracker_full tf set user_id = (select user_id from user_translation ut where tf.changedby = ut.orig_username);


/* Prepare the protocols / sub_processes / protocol_events */
select distinct ROW_NUMBER() over () "id", 
  protocol_name,
  1 "protocol_id", 
  sub_process_name, 
  2 "sub_process_id", 
  protocol_event_name
into temporary tracker_migration_lookup
from tracker_full group by protocol_name, sub_process_name, protocol_event_name, trim(outcome);

/* Make a protocol_id number for each protocol name */
update tracker_migration_lookup set protocol_id = 2 where protocol_name = 'Q1';
/*update tracker_migration_lookup set protocol_id = 2 where protocol_name = 'R1';*/
update tracker_migration_lookup set protocol_id = 3 where protocol_name = 'General Awareness';
/* update tracker_migration_lookup set protocol_id = 4 where protocol_name = 'Inquiry'; */
 
/* create the remaining ids for sub_process and process_event */
select protocol_name, protocol_id, sub_process_name, first_value(id) over(partition by protocol_id, sub_process_name) "sub_process_id", protocol_event_name, id "event_id" 
into temp tracker_migration_lookup_ids from tracker_migration_lookup order by protocol_id, sub_process_name;


/* make the inserts into the lookup tables */
insert into protocols (id, name, created_at, updated_at) select distinct protocol_id, protocol_name, now(), now() from tracker_migration_lookup_ids;
insert into sub_processes(id, name, created_at, updated_at, protocol_id) select distinct sub_process_id, sub_process_name, now(), now(), protocol_id from tracker_migration_lookup_ids group by sub_process_name, sub_process_id, protocol_id;
/* take care to handle the null event names and dups in the lookup table */
insert into protocol_events(id, name, created_at, updated_at, sub_process_id) select  min(event_id), protocol_event_name, now(), now(), sub_process_id from tracker_migration_lookup_ids where protocol_event_name is not null group by protocol_event_name, sub_process_id;

/* force the sequences to update correctly */
SELECT setval('protocols_id_seq', (SELECT MAX(id) FROM protocols));
SELECT setval('sub_processes_id_seq', (SELECT MAX(id) FROM sub_processes));
SELECT setval('protocol_events_id_seq', (SELECT MAX(id) FROM protocol_events));


/* set the id  for protocol, sub process and protocol event in the temp tracker_full table */

/* get the protocol_id for the calculated protocol name */

update tracker_full tf set protocol_id = (select distinct id from protocols where protocols.name = tf.protocol_name );

/* get the sub_process_id for the calculated sub process name */
update tracker_full tf set sub_process_id = (select distinct id from sub_processes where sub_processes.name = tf.sub_process_name and tf.protocol_id = sub_processes.protocol_id);

/* Create a unique list of protocol_events */
select distinct min(pe.id) "protocol_event_id", pe.name "protocol_event_name", pe.sub_process_id  into temp p_list from sub_processes sp inner join protocol_events pe on sp.id = pe.sub_process_id  group by protocol_event_name, sub_process_id;


/* get the protocol_event_id for the calculated protocol event name */
/*update tracker_full tf set protocol_event_id = ( select distinct id from protocol_events where protocol_events.name = tf.protocol_event_name and tf.sub_process_id =  protocol_events.sub_process_id and tf.protocol_event_name is not null);*/
update tracker_full tf set protocol_event_id = ( select distinct protocol_event_id from p_list where ((protocol_event_name is null AND tf.protocol_event_name is NULL) OR protocol_event_name = tf.protocol_event_name) and tf.sub_process_id =  p_list.sub_process_id);


/* generate the event date for the new tracker - use the first one available from the following:  outcome_date, event_date, lastmod */
update tracker_full set new_event_date = case when outcome_date is not null then outcome_date when event_date is not null then event_date else lastmod end ;



/* pull the latest tracker entry for each msid / protocol pair */
select distinct on (msid, protocol_id) id, msid, new_event_date into temp tracker_latest from tracker_full order by msid, protocol_id, new_event_date desc, id;


/* now insert the latest records into tracker 
    assume that the creation and update date for the record is the lastmod date if set, otherwise use the event date
*/

insert into ml_app.trackers 
(master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id, notes, user_id)
select 
    masters.id, tf.protocol_id, tf.new_event_date, 
    case when lastmod is null then event_date else lastmod end "created_at", 
    case when lastmod is null then event_date else lastmod end "updated_at", 
    tf.sub_process_id, tf.protocol_event_id, tf.notes, tf.user_id
from tracker_full tf
inner join tracker_latest on tracker_latest.id = tf.id 
inner join masters on masters.msid = tracker_latest.msid;

/* clear the tracker_history */
delete from ml_app.tracker_history;

/* Now go and add the history items that were not in the 'latest' set.
 * Add these, linking the tracker_id back to the matching tracker record created above that has a matching msid and protocol pair
 * We create a temp table to allow comparison of results in the checks below
 */

select 
    masters.id "master_id", tf.protocol_id "protocol_id", tf.new_event_date "event_date", 
    case when lastmod is null then event_date else lastmod end "created_at", 
    case when lastmod is null then event_date else lastmod end "updated_at", 
    tf.sub_process_id "sub_process_id", tf.protocol_event_id "protocol_event_id", trackers.id "tracker_id", trackid, tf.notes, tf.user_id
into temp tracker_hist_only
from tracker_full tf 
inner join masters on masters.msid = tf.msid
inner join trackers on trackers.master_id = masters.id and trackers.protocol_id = tf.protocol_id
where not exists ( select id from tracker_latest tl where tl.id = tf.id);

/* Careful ordering of records is required to ensure appropriate retrieval for tracker history
   Records must be inserted in order so tracker_history.id increments correctly. To ensure chronology, we 
   order finally by trackid (the original tracker sequence id) to ensure that matching event dates can be appropriately ordered
   based on the order they were entered originally.
*/
insert into ml_app.tracker_history 
(master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id, tracker_id, notes, user_id)
select master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id, tracker_id, notes, user_id
from tracker_hist_only order by event_date desc, trackid;

/* Finally, force the latest tracker items back into the tracker_history */
update trackers set updated_at = now();

