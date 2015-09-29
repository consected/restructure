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
update player_contacts a3 
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


