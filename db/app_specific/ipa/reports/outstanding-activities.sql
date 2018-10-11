SELECT
   dt.master_id,
   pi.first_name,
   pi.last_name,
   dt.source,
   dt.extra_log_type activity,
   dt.communication_result,
   dt.checklist_signed,
   dt.exit_type,
   dt.created_at,
   dt.r
FROM (

  SELECT
    di.*,
    dlo.exit_type,
    rank()
    OVER (
    PARTITION BY di.master_id
    ORDER BY di.created_at DESC
    ) AS r
  FROM
  (
    SELECT
      al.master_id,
      'tracker' "source",
      al.extra_log_type,
      al.select_result "communication_result",
      NULL "checklist_signed",
      al.created_at

    FROM activity_log_ipa_assignments al

    WHERE
    :activity_performed = 'general-follow-up' AND al.extra_log_type='general' AND select_result='follow up'
    OR
    :activity_performed = 'general-completed' AND al.extra_log_type='general' AND select_result='completed'
    OR
    :activity_outstanding is not null AND :activity_outstanding = 'general-follow-up' AND al.extra_log_type='general'
    OR
    :activity_outstanding is not null AND :activity_outstanding = 'general-completed' AND al.extra_log_type='general'
    OR
    (
      al.extra_log_type IN (:activity_performed, :activity_outstanding, 'withdraw', 'perform_screening_follow_up')
    )

    UNION

    SELECT
      inex.master_id,
      'inex' "source",
      inex.extra_log_type,
      NULL "communication_result",
      inex.signed_no_yes "checklist_signed",
      inex.created_at


    FROM activity_log_ipa_assignment_inex_checklists inex
    WHERE

    (:activity_performed = 'inex-complete' OR :activity_outstanding IS NOT NULL AND :activity_outstanding  = 'inex-complete' )
    AND extra_log_type IN ('sign_phone_screen_staff', 'sign_baseline_staff')





  ) AS di

  LEFT OUTER JOIN (

    SELECT
      master_id,
      'not interested or ineligible (follow up)' "exit_type"


    FROM ipa_screenings ps
    WHERE
      still_interested_blank_yes_no = 'no' OR
      eligible_for_study_blank_yes_no = 'no'


    UNION

    SELECT
      master_id,
      'not interested (phone screening)' "exit_type"

    FROM ipa_ps_initial_screenings inits
    WHERE
     select_is_good_time_to_speak = 'not interested' OR
     select_may_i_begin = 'not interested' OR
     select_still_interested = 'no'

    UNION

    SELECT
      master_id,
      'withdrew' "exit_type"

    FROM ipa_withdrawals wd
    WHERE
     select_subject_withdrew_reason = 'withdrew' OR
     select_investigator_terminated IN ('yes - due to ae', 'yes - other reason') OR
     lost_to_follow_up_no_yes = 'yes' OR
     no_longer_participating_no_yes = 'yes'

     UNION

    SELECT
      master_id,
      'completed exit survey' "exit_type"
    FROM ipa_surveys surv
    WHERE
      select_survey_type = 'exit survey'
  ) dlo ON dlo.master_id = di.master_id

) AS dt

inner join player_infos pi on dt.master_id = pi.master_id

WHERE
(:activity_outstanding IS NULL OR :activity_outstanding IS NOT NULL AND r = 1)
AND
(

  :activity_performed = 'general-follow-up' AND dt.extra_log_type='general' AND dt.communication_result='follow up'
  OR
    :activity_performed = 'general-completed' AND dt.extra_log_type='general' AND dt.communication_result='completed'
  OR (
    :activity_performed = 'inex-complete'
    AND (
      dt.extra_log_type IN ('sign_phone_screen_staff', 'sign_baseline_staff') AND
      checklist_signed = 'yes'
    )
  )
  OR :activity_performed <> 'inex-complete' AND dt.extra_log_type = :activity_performed
)
AND (
  :activity_outstanding IS NULL
  OR NOT (
    r = 1
    AND (
      :activity_outstanding = 'general-follow-up' AND dt.extra_log_type='general' AND dt.communication_result='follow up'
      OR :activity_outstanding = 'general-completed' AND dt.extra_log_type='general' AND dt.communication_result='completed'
      OR (
          :activity_outstanding = 'inex-complete'
          AND (
            dt.extra_log_type IN ('sign_phone_screen_staff', 'sign_baseline_staff') AND
            checklist_signed = 'yes'
          )
      )
      OR :activity_outstanding <> 'inex-complete' AND dt.extra_log_type = :activity_outstanding
    )
  )

)
AND (
  :completed_or_withdrawn IS NULL
  OR (
    :completed_or_withdrawn = 'in_study' AND dt.exit_type IS NULL
    OR
    :completed_or_withdrawn = 'not_in_study' AND dt.exit_type IS NOT NULL
  )
)
ORDER BY
  dt.created_at DESC
;
