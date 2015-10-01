/* Now validate the results */


/* Initial checks on master list records */
select count(*) from ml_copy;
/*-------
 23806
*/

select count(distinct msid) from ml_copy;
/*-------
 23771
*/

/* The number of master records we expect */
select count(*) from (select distinct msid, pro_id from ml_copy where msid is not null and (accuracy_score is null or accuracy_score <> -1 and accuracy_score <> 999)) as t;
/*-------
 16188
*/

/* The actual number of masters records */
select count(*) from masters;
/*-------
 23806
*/

select count(distinct msid) from masters;
/*-------
 23771
*/


/* Get counts of msid / accuracy_score categories from ml_copy */
select case when accuracy_score is null then 'accuracy score null' when msid is null then 'msid null: ' || accuracy_score else 'msid exists: ' || accuracy_score end "rule", count(*) from ml_copy where msid is null or accuracy_score = -1 or accuracy_score = 999 or accuracy_score is null group by accuracy_score, rule;
/*
        rule         | count 
---------------------+-------
 accuracy score null |     1
 msid exists: -1     |  7606
 msid exists: 999    |    12

*/
    

/* Total to reject (not including any null accuracy scores) */
select count(*) from ml_copy where msid is null or (accuracy_score is not null and (accuracy_score = -1 or accuracy_score = 999)); 
/*-------
 7618
*/

/* which means that masters should eventually contain */
select count(*) from ml_copy where not(msid is null or (accuracy_score is not null and (accuracy_score = -1 or accuracy_score = 999))); 
/*-------
 16188
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


/* -----------------------------
 *  tracker list validations 
 * -----------------------------*/


/* check trackers and tracker_latest have corresponding numbers */
select count(*) from tracker_latest;
/*-------
 22384
*/

select count(*) from trackers;
/*-------
 22387
*/

/* They don't match... because of a strange inner join effect ... This is what is happening...*/
/* the original query that populated tracker_latest returns the expected number of rows */
select count(*) from (select distinct on (msid, protocol_id) id, msid, new_event_date from tracker_full order by msid, protocol_id, event_date desc, id) as t;
/*-------
 22384
*/
/* But when joined with the masters table to allow association with a masters.id, the count jumps by 7 */
select count(*) from tracker_latest inner join masters on masters.msid = tracker_latest.msid;
/*-------
 29387
*/


/* Find the duplicates, based on the joined masters table */
select distinct tlo.id, tlo.msid, mo.pro_id from tracker_latest tlo  inner join masters mo on mo.msid = tlo.msid where tlo.id in (select tl.id from tracker_latest tl inner join masters on masters.msid = tl.msid  group by tl.id having count(1) > 1) order by tlo.msid;
/*
  id   |  msid  | pro_id 
-------+--------+--------
 61285 | 108973 |    268
 61677 | 110326 |   7663
 61944 | 119562 |   6662

*/

/* Here we have 3 rows that have an msid that appears duplicated after the join. 3 msids are affected. If the MSIDs were unique 
   we would expect one record for each of the 4 msids to have made it in to trackers.
   The remainder are the 0 additional records that we see after the join.
*/


/* to test this, create a temporary list of unique msids in the masters table. The result should be that the temporary
    tracker_latest and trackers tables should now match. */
select distinct on(msid) id, msid, pro_id  into temp unique_masters from masters;

select 
   (select count(*) from tracker_latest) "latest", 
   (select count(*) from trackers inner join unique_masters on unique_masters.id = trackers.master_id) "trackers";
/* 
 latest | trackers 
--------+----------
  29360 |    29360
*/


/* tracker history count should =  
  records inserted into ml_app.trackers
+ records inserted directly in ml_app.tracker_history
*/

select (select count(*) from ml_app.trackers) "trackers", '+', 
  (select count(*) from tracker_hist_only) "history only", '=', 
  (select count(*) from trackers) + (select count(*) from tracker_hist_only) "total", 'matches?', 
  (select count(*) from ml_app.tracker_history) "tracker history";
/*
 trackers | ?column? | history only | ?column? | total | ?column? | tracker history 
----------+----------+--------------+----------+-------+----------+-----------------
    29367 | +        |        28429 | =        | 57796 | matches? |           57796
*/


/* In a perfect world, tracker_full (the full set of original tracker data with the items missing MSIDs discarded) will match the entries in 
   ml_app.tracker_history 
   We are seeing 8 additional records in ml_app.tracker_history after migration.

   We know that 7 additional records appear in trackers than due to duplicate msids, leaving just one unaccounted for.

*/
select count(*)  from tracker_full;
/*-------
 62167
*/

/* we also have a mismatch between the number of actual records pushed directly into ml_app.tracker_history and the 
   expected records, due to the dup msids in masters.
   This accounts for the additional 1 record we're seeing in the full set of tracker records compared to tracker_full.

 */
select (select count(*) from tracker_hist_only) - (select count(*) from tracker_hist_only tho inner join unique_masters on unique_masters.id = tho.master_id) "diff";
/* diff 
------
    4
*/



/* Check that original and new tracker(s) tables have the correct number of records 
> tracker_full represents the union of ml_work tracker and tracker_history tables, with records missing from masters removed 
  We expect this value to be 0 (although currently it isn't)

*/
select (select count(*) from ml_app.tracker_history) - (select count(*) from tracker_full) "result";
/*
7
*/

/* Check that there are no fields we have not transferred. The result should be 0 */
select count(*) from tracker where emid is not null or addrid is not null or resent is not null or ty_method is not null or ty_sent is not null;
/* 0 */


/* check the results in both directions */
select count(*) from ml_app.tracker_history th  where  not exists (select trackid from tracker_full tf inner join masters on masters.msid = tf.msid where masters.id = th.master_id );

select count(*) from tracker_full tf inner join masters on masters.msid = tf.msid where not exists (select id from ml_app.tracker_history th  where masters.id = th.master_id );



/* ADDRESSES */
/* Validate that there are no addresses remaining where there is not a well defined set of ranks */
select * from addresses where master_id in (select  master_id from addresses group by  master_id having count(1) > 1 and count(1) <> count(distinct rank)) order by master_id;

/* Compare  the number of addresses that are not distinct in each master record */
select count(*) from (select  distinct master_id, street, street2, street3, city, state, zip, rec_type from addresses) t; 
/*-------
 31694
*/

select count(*) from (select  master_id, street, street2, street3, city, state, zip, rec_type from addresses) t;
/*-------
 32221
*/

/* validate it */
select id, rank from addresses a3 
  where (id, master_id) in (
    select max(id) "id", master_id 
      from addresses a1 
      where (rank, master_id) in (
        select max(rank), master_id 
          from addresses a2 
          group by master_id 
      ) 
      group by master_id) ;



/* Player Contacts */

/* validate it */
select master_id, id, rank, rec_type from player_contacts a3 
where (id, master_id, rec_type) in (
  select max(id) "id", master_id, rec_type 
  from player_contacts a2 
  where (rank, master_id, rec_type) in (
    select max(rank), master_id, rec_type 
    from player_contacts a1 
    where rank <> -1 
    group by master_id, rec_type 
  ) 
  group by master_id, rec_type
) order by master_id;

/* update to set secondary ranks for all that have not been set as primary and are not 0 */
update player_contacts set rank = 5 where rank <> 10 and rank <> 5 and rank <> 0 and rank <> -1;



/* create a temp table for unique msids */
drop table if exists unique_masters;
select distinct on (msid) msid, id into temp unique_masters from masters order by msid, id;

/* get the original count of player contacts associated with the unique set of msids */
select count(distinct pcid) from ml_work.playercontact pc inner join masters m on m.msid = pc.msid;
/* count 
-------
 11052
*/

/* Check the new count of player contacts corresponds */
select count (distinct pc.id) from player_contacts pc 
inner join unique_masters m on m.id = pc.master_id 
inner join ml_work.playercontact pcold on pcold.msid = m.msid;
/* count 
-------
 11052
*/

/* Check for the number of inactive items in the records that are included in the master list */
select count(distinct pcid) from ml_work.playercontact pc inner join unique_masters m on m.msid = pc.msid where active = 0;
/* count 
-------
  1644
*/

select count (distinct pc.id) from player_contacts pc 
inner join unique_masters m on m.id = pc.master_id 
inner join ml_work.playercontact pcold on 
  pcold.msid = m.msid  and 
  trim(lower(pcold.pcdata)) =  trim(lower(pc.data)) and   
  pcold.lastmod = pc.updated_at
where active = 0;


