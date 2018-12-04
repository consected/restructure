SELECT
  dt.master_id,
  first_name,
  last_name,
  follow_up_when,
  select_next_step,
  protocols.name,
  data,
  select_call_direction,
  select_who,
  users.email username,
  called_when,
  select_result,
  notes

FROM (
 SELECT
   master_id,
   follow_up_when,
   data,
   select_call_direction,
   select_who,
   called_when,
   select_result,
   select_next_step,
   protocol_id,
   user_id,
   notes,
   rank()
 OVER (
   PARTITION BY master_id
   ORDER BY called_when DESC, id DESC
 ) AS r
 FROM activity_log_player_contact_phones
) AS dt

INNER JOIN player_infos pi
ON pi.master_id = dt.master_id
LEFT OUTER JOIN users
ON dt.user_id = users.id
LEFT OUTER JOIN protocols
ON dt.protocol_id = protocols.id

WHERE
  r = 1
AND
  (
    select_next_step IN ('call back', 'more info requested')
    OR follow_up_when IS NOT NULL
  )
AND
   (
     :protocol IS NULL
     OR protocol_id = :protocol
   )
AND
  (
    :select_who IS NULL OR
    :select_who <> 'user' AND select_who = :select_who OR
    :select_who = 'user' AND select_who = :select_who AND (:username IS NULL OR dt.user_id = :username)
  )
AND
  (
    :follow_up_before IS NULL
    OR follow_up_when <= :follow_up_before
  )
ORDER BY
  follow_up_when DESC,
  called_when ASC
;
