set SEARCH_PATH=ml_app,ml_work;

drop table temp tracker_full;
drop table tracker_migration_lookup;
drop table tracker_migration_lookup_ids;
drop table tracker_latest;
drop table tracker_hist_only;

delete from ml_app.tracker_history;
delete from ml_app.trackers;
delete from ml_app.protocol_events;
delete from ml_app.sub_processes;
delete from ml_app.protocols;
delete from masters;


/* Create the master list of msids - note this picks only the distinct msid entries,*/
insert into masters (msid, pro_id) select distinct msid, pro_id from ml_copy where msid is not null and (accuracy_score is null or accuracy_score <> -1 and accuracy_score <> 999);

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
select protocol_name, protocol_id, sub_process_name, first_value(id) over(partition by protocol_id, sub_process_name) "sub_process_id", protocol_event_name, id "event_id" 
into temp tracker_migration_lookup_ids from tracker_migration_lookup order by protocol_id, sub_process_name;


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
 * We create a temp table to allow comparison of results in the checks below
 */

select masters.id "master_id", tf.protocol_id "protocol_id", tf.event_date "event_date", now() "created_at", now() "updated_at", 
tf.sub_process_id "sub_process_id", tf.protocol_event_id "protocol_event_id", trackers.id "tracker_id"
into temp tracker_hist_only
from tracker_full tf 
inner join masters on masters.msid = tf.msid
inner join trackers on trackers.master_id = masters.id and trackers.protocol_id = tf.protocol_id
where not exists ( select id from tracker_latest tl where tl.id = tf.id)
;

insert into ml_app.tracker_history 
(master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id, tracker_id)
select master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id, tracker_id
from tracker_hist_only;



/* Now validate the results */


/* Initial checks on master list records */
select count(*) from ml_copy;
/*-------
 34902
*/

select count(distinct msid) from ml_copy;
/*-------
 23189
*/

select count(distinct msid) from masters;
/*-------
 16935
*/



select case when accuracy_score is null then 'accuracy score null' when msid is null then 'msid null: ' || accuracy_score else 'msid exists: ' || accuracy_score end "rule", count(*) from ml_copy where msid is null or accuracy_score = -1 or accuracy_score = 999 or accuracy_score is null group by accuracy_score, rule;
/*
        rule         | count 
---------------------+-------
 accuracy score null |     1
 msid exists: -1     |  6244
 msid null: -1       |  6334
 msid exists: 999    |   700
*/


/* Total to reject (not including any null accuracy scores) */
select count(*) from ml_copy where msid is null or (accuracy_score is not null and (accuracy_score = -1 or accuracy_score = 999)); 
/*-------
 13278
*/

/* which means that masters should eventually contain */
select count(*) from ml_copy where not(msid is null or (accuracy_score is not null and (accuracy_score = -1 or accuracy_score = 999))); 
/*-------
 21624
*/

/* masters represents all master list records from the previous query - the numbers should match */
select count(*) from masters;
/*-------
 21624
*/

/* Validate that the master list plus the rejected list matches the total for ml_copy */
select (select count(*) from masters) + (select count(*) from ml_copy where msid is null or (accuracy_score is not null and (accuracy_score = -1 or accuracy_score = 999))) - (select count(*) from ml_copy) "result";
/*
 result 
--------
      0
*/


/* tracker list validations */


/* check trackers and tracker_latest have corresponding numbers */
select count(*) from tracker_latest;
/*-------
 29360
*/

select count(*) from tracker_latest inner join masters on masters.msid = tracker_latest.msid;
/*-------
 29367
*/

/* Find the duplicates, based on the joined masters table */
select distinct tlo.id, tlo.msid, mo.pro_id from tracker_latest tlo  inner join masters mo on mo.msid = tlo.msid where tlo.id in (select tl.id from tracker_latest tl inner join masters on masters.msid = tl.msid  group by tl.id having count(1) > 1) order by tlo.msid;
/*
  id   |  msid  | pro_id 
-------+--------+--------
 57738 | 108973 |    267
 57738 | 108973 |    268
 48315 | 114535 |   9267
 48315 | 114535 |   9268
 57767 | 119562 |   6662
 57767 | 119562 |   6663
 47352 | 122502 |   9659
 47352 | 122502 |   9660
 47352 | 122502 |   9661
 47352 | 122502 |   9665
 47352 | 122502 |   9753
*/


/* tracker history count should =  
  records inserted into ml_app.trackers
+ records inserted directly in ml_app.tracker_history
*/

select (select count(*) from trackers) "trackers", '+', (select count(*) from tracker_hist_only), '=', (select count(*) from trackers) + (select count(*) from tracker_hist_only) "total";
/*
 trackers | ?column? | count | ?column? | total 
----------+----------+-------+----------+-------
    29367 | +        | 28429 | =        | 57796

*/


select count(*) from ml_app.tracker_history;
/*-------
 57796
*/
select count(*) from tracker_full;
/*-------
 57788
*/

/* Check that original and new tracker(s) tables have the correct number of records 
> tracker_full represents the union of ml_work tracker and tracker_history tables, with records missing from masters removed */
select (select count(*) from ml_app.tracker_history) - (select count(*) from tracker_full) "result";


/* Check that there are no fields we have not transferred. The result should be 0 */
select count(*) from tracker where emid is not null or addrid is not null or resent is not null or ty_method is not null or ty_sent is not null;



/* check the results in both directions */
select count(*) from ml_app.tracker_history th  where  not exists (select trackid from tracker_full tf inner join masters on masters.msid = tf.msid where masters.id = th.master_id );

select count(*) from tracker_full tf inner join masters on masters.msid = tf.msid where not exists (select id from ml_app.tracker_history th  where masters.id = th.master_id );


 select count(distinct th.id) from ml_app.tracker_history th inner join masters on th.master_id = masters.id inner join tracker_full tf on masters.msid = tf.msid;
