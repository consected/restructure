set SEARCH_PATH=ml_app;


update addresses set street2 = null where street2 ~* 'null';
/* UPDATE 511
*/


update addresses set rank = -10 where rank is null;


/* Query to handle the following: 
  a1: selects just the addresses belonging to the same master record with the highest rank
  a2: refines this by selecting the max id from each master id, to handle the few cases where there are duplicate max ranks that match
  
*/
update 
addresses a3 
set rank = 10
where (id, master_id) in (
  select max(id) "id", master_id 
  from addresses a2 
  where (rank, master_id) in (
    select max(rank), master_id 
    from addresses a1 
    group by master_id 
  ) 
  group by master_id
);


/* validate it */
select id, rank from addresses a3 where (id, master_id) in (select max(id) "id", master_id from addresses a1 where (rank, master_id) in (select max(rank), master_id from addresses a2 group by master_id ) group by master_id) ;

/* update to set secondary ranks for all that have not been set as primary and are not 0 */
update addresses set rank = 5 where rank <> 10 and rank <> 5 and rank <> 0;

/* To finish, validate that there are no addresses remaining where there is not a well defined set of ranks */
select * from addresses where master_id in (select  master_id from addresses group by  master_id having count(1) > 1 and count(1) <> count(distinct rank)) order by master_id;



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
