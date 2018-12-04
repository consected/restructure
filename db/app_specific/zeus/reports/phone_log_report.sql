select
dt.master_id,
protocols.name,
pi.first_name,
pi.last_name,
dt.data phone,
dt.select_call_direction,
dt.select_who,
users.email,
dt.called_when,
dt.select_result,
dt.select_next_step,
dt.follow_up_when,
dt.notes


FROM  activity_log_player_contact_phones dt
INNER JOIN player_infos pi
ON pi.master_id = dt.master_id
INNER JOIN users
ON dt.user_id = users.id
LEFT OUTER JOIN protocols
ON dt.protocol_id = protocols.id
where
(:called_from is null OR called_when >= :called_from)
 AND
(:called_to is null OR called_when <= :called_to)
