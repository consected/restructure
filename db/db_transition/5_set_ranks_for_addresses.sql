set SEARCH_PATH=ml_app;


update addresses set rank = -10 where rank is null;
update addresses set rank = 10 where lower(source) = 'cis';

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


/* update to set secondary ranks for all that have not been set as primary and are not 0 */
update addresses set rank = 5 where rank <> 10 and rank <> 5 and rank <> 0;

