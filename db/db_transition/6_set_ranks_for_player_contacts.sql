set SEARCH_PATH=ml_app;


update player_contacts set rec_type='email' where data ~ '.*@.*' and rec_type <> 'email';
/* UPDATE 2 */

update player_contacts set rec_type='phone' where data ~ '\(?\d{3}\)?[\s|-]?\d{3}-?\d{4}$' and rec_type<>'phone';
/* UPDATE 1 */

select msid, data from player_contacts pc inner join masters m on m.id = pc.master_id where data !~ '.*@.*\..+$' and rec_type = 'email';
update player_contacts set rank = -1 where data !~ '.*@.*\..+$' and rec_type = 'email';
/* UPDATE 15 */

select msid, data from player_contacts pc inner join masters m on m.id = pc.master_id where data !~ '\(?\d{3}\)?[\s|-]?\d{3}-?\d{4}( .*)?$' and rec_type='phone';
update player_contacts set rank = -1 where data !~ '\(?\d{3}\)?[\s|-]?\d{3}-?\d{4}( .*)?$' and rec_type='phone';
/* UPDATE 6 */

update player_contacts set rank = -10 where rank is null;


/* Query to handle the following: 
  a1: selects just the addresses belonging to the same master record with the highest rank
  a2: refines this by selecting the max id from each master id, to handle the few cases where there are duplicate max ranks that match
  
*/
update 
player_contacts a3 
set rank = 10
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
);


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



/* Additional info, if required */




/* Compare  the number of addresses that are not distinct in each master record */
select count(*) from (select  distinct master_id, street, street2, street3, city, state, zip, rec_type from addresses) t; 
/*-------
 31694
*/

select count(*) from (select  master_id, street, street2, street3, city, state, zip, rec_type from addresses) t;
/*-------
 32221
*/

