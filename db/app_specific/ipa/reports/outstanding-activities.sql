SELECT
   dt.master_id,
   ipa.ipa_id,
   --pi.first_name,
   --pi.last_name,
   dt.source,
   dt.extra_log_type activity,
   dt.communication_result,
   dt.checklist_signed,
   dt.exit_type,
   dt.created_at,
   dt.r
FROM (
  -- Generate a resultset of ranked results
  -- with most recently created items first
  -- that include only the requested previous and outstanding activities
  -- This allows us to see if an outstanding item appears more recently than
  -- a previous item

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
    --
    -- IPA Tracker process
    --
    SELECT
      al.master_id,
      'tracker' "source",
      al.extra_log_type,
      CASE WHEN
        (select_result='follow up' OR select_activity = 'schedule follow up') THEN 'follow up'
      WHEN
        (select_result='completed' OR select_activity = 'completed') THEN 'completed'
      ELSE
        al.select_result
      END "communication_result",
      NULL "checklist_signed",
      al.created_at

    FROM activity_log_ipa_assignments al

    WHERE
      :activity_performed = 'general-follow-up' AND al.extra_log_type='general' AND (select_result='follow up' OR select_activity = 'schedule follow up')
      OR :activity_performed = 'general-completed' AND al.extra_log_type='general' AND (select_result='completed' OR select_activity = 'completed')
      OR :activity_outstanding is not null AND :activity_outstanding = 'general-follow-up' AND al.extra_log_type='general'
      OR :activity_outstanding is not null AND :activity_outstanding = 'general-completed' AND al.extra_log_type='general'
      OR al.extra_log_type IN (:activity_performed, :activity_outstanding, 'withdraw', 'perform_screening_follow_up')

    UNION

    --
    -- IPA Tracker process for appointments
    --
    SELECT
      al.master_id,
      'tracker' "source",
      al.extra_log_type,
      NULL "communication_result",
      NULL "checklist_signed",
      '1900-01-01 00:00:00'

    FROM activity_log_ipa_assignments al

    INNER JOIN ipa_appointments apt
    ON al.master_id = apt.master_id

    WHERE
      :activity_performed = 'appointment-set' AND al.extra_log_type='appointment'
      OR :activity_outstanding is not null AND :activity_outstanding = 'appointment-set' AND al.extra_log_type='appointment'

    UNION
    --
    -- Inclusion / Exclusion process
    --
    SELECT
      inex.master_id,
      'inex' "source",
      inex.extra_log_type,
      NULL "communication_result",
      inex.signed_no_yes "checklist_signed",
      inex.created_at


    FROM activity_log_ipa_assignment_inex_checklists inex

    WHERE

    (
      (
        :activity_performed = 'inex-phone-screen-finalized' AND extra_log_type = 'finalize_phone_screen_checklist'
        OR :activity_performed = 'inex-phone-screen-so-pi' AND extra_log_type = 'sign_phone_screen'
        OR :activity_performed = 'inex-phone-screen-so-mednav' AND extra_log_type = 'sign_phone_screen_reviewer'
        OR :activity_performed = 'inex-phone-screen-so-staff' AND extra_log_type = 'sign_phone_screen_staff'
        OR :activity_performed = 'inex-baseline-complete' AND extra_log_type = 'sign_baseline'
        OR :activity_performed = 'inex-tms-responses' AND extra_log_type = 'tms_responses'
        OR :activity_performed = 'inex-tms-so' AND extra_log_type = 'sign_tms_eligibility'
      )


      OR :activity_outstanding IS NOT NULL AND (
        :activity_outstanding = 'inex-phone-screen-finalized' AND extra_log_type = 'finalize_phone_screen_checklist'
        OR :activity_outstanding = 'inex-phone-screen-so-pi' AND extra_log_type = 'sign_phone_screen'
        OR :activity_outstanding = 'inex-phone-screen-so-mednav' AND extra_log_type = 'sign_phone_screen_reviewer'
        OR :activity_outstanding = 'inex-phone-screen-so-staff' AND extra_log_type = 'sign_phone_screen_staff'
        OR :activity_outstanding = 'inex-baseline-complete' AND extra_log_type = 'sign_baseline'
        OR :activity_outstanding = 'inex-tms-responses' AND extra_log_type = 'tms_responses'
        OR :activity_outstanding = 'inex-tms-so' AND extra_log_type = 'sign_tms_eligibility'
      )
    )

    UNION

    --
    -- Phone Screen process
    --
    SELECT
      ps.master_id,
      'phone screen' "source",
      'phone_screen_finalized' "extra_log_type",
      NULL "communication_result",
      NULL "checklist_signed",
      ps.created_at

    FROM activity_log_ipa_assignment_phone_screens ps

    WHERE
      (:activity_performed = 'phone-screen-complete' OR :activity_outstanding IS NOT NULL AND :activity_outstanding  = 'phone-screen-complete' )
      AND extra_log_type IN ('finalize')



    UNION

    --
    -- Navigation process
    --
    SELECT
      master_id,
      'navigation' "source",
      extra_log_type,
      NULL "communication_result",
      NULL "checklist_signed",
      coalesce(event_date + start_time, created_at) "created_at"

    FROM activity_log_ipa_assignment_navigations nav

    WHERE
    (
      (
        :activity_performed = 'has-planned-event' AND extra_log_type = 'planned_event'
        OR :activity_performed = 'has-event-feedback' AND extra_log_type = 'station_event'
      )

      OR :activity_outstanding IS NOT NULL AND (
        :activity_outstanding  = 'has-planned-event' AND extra_log_type = 'planned_event'
        OR :activity_outstanding = 'has-event-feedback' AND extra_log_type = 'station_event'
      )
    )


  ) AS di

  LEFT OUTER JOIN (
    -- Add an exit type column for those participants that have exited the study
    -- NULL if they are still in the study

    --
    -- Phone Screen not interested or not eligible
    --
    SELECT
      master_id,
      'not interested or ineligible (follow up)' "exit_type"


    FROM ipa_screenings ps
    WHERE
      still_interested_blank_yes_no = 'no' OR
      eligible_for_study_blank_yes_no = 'no'


    UNION

    --
    -- Phone screen not interested
    --
    SELECT
      master_id,
      'not interested (phone screening)' "exit_type"

    FROM ipa_ps_initial_screenings inits
    WHERE
     select_is_good_time_to_speak = 'not interested' OR
     select_may_i_begin = 'not interested' OR
     select_still_interested = 'no'

    UNION

    --
    -- Withdrew
    --
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

    --
    -- Completed study
    --
    SELECT
      master_id,
      'completed exit survey' "exit_type"
    FROM ipa_surveys surv
    WHERE
      select_survey_type = 'exit survey'

  -- End left outer join
  ) dlo ON dlo.master_id = di.master_id

-- End ranked selection
) AS dt

-- Include player details
inner join player_infos pi on dt.master_id = pi.master_id
-- Match IPA ID to master_id
inner join ipa_assignments ipa on dt.master_id = ipa.master_id

WHERE
(
  -- Either:
  -- no outstanding activity has been selected, so just perform a plain query
  -- or:
  -- we want the first record from the results based
  -- on an order of most recently created appearing first (and therefore overriding older records)
  :activity_outstanding IS NULL OR :activity_outstanding IS NOT NULL AND r = 1
)
AND
(
  -- Based on the activity performed selection pick the appropriate conditions
  :activity_performed = 'general-follow-up' AND extra_log_type='general' AND dt.communication_result='follow up'
  OR :activity_performed = 'general-completed' AND extra_log_type='general' AND dt.communication_result='completed'
  OR :activity_performed = 'inex-phone-screen-finalized' AND extra_log_type = 'finalize_phone_screen_checklist'
  OR :activity_performed = 'inex-phone-screen-so-pi' AND extra_log_type = 'sign_phone_screen'
  OR :activity_performed = 'inex-phone-screen-so-mednav' AND extra_log_type = 'sign_phone_screen_reviewer'
  OR :activity_performed = 'inex-phone-screen-so-staff' AND extra_log_type = 'sign_phone_screen_staff'
  OR :activity_performed = 'inex-tms-responses' AND extra_log_type = 'tms_responses'
  OR :activity_performed = 'inex-tms-so' AND extra_log_type = 'sign_tms_eligibility'
  OR :activity_performed = 'phone-screen-complete' AND extra_log_type = 'phone_screen_finalized'
  OR :activity_performed = 'has-planned-event' AND extra_log_type = 'planned_event'
  OR :activity_performed = 'has-event-feedback' AND extra_log_type = 'station_event'
  OR :activity_performed = 'appointment-set' AND extra_log_type='appointment'

  OR (
    :activity_performed = 'inex-baseline-complete'
    AND (
      extra_log_type IN ('sign_baseline') AND
      checklist_signed = 'yes'
    )
  )

  OR :activity_performed NOT IN ('inex-complete', 'phone-screen-complete') AND extra_log_type = :activity_performed
)
AND (
  -- If no outstanding activity was selected then there are no conditions to apply
  :activity_outstanding IS NULL
  OR NOT (
    -- An outstanding activity was selected
    -- Based on the activity outstanding selection pick the appropriate conditions
    -- that the first record in the results must match in order to correctly override the previous activities
    -- If one was found, the NOT negation ensures a found record does not register as an activity outstanding
    r = 1
    AND (
      :activity_outstanding = 'general-follow-up' AND extra_log_type='general' AND dt.communication_result='follow up'
      OR :activity_outstanding = 'general-completed' AND extra_log_type='general' AND dt.communication_result='completed'
      OR :activity_outstanding = 'inex-phone-screen-finalized' AND extra_log_type = 'finalize_phone_screen_checklist'
      OR :activity_outstanding = 'inex-phone-screen-so-pi' AND extra_log_type = 'sign_phone_screen'
      OR :activity_outstanding = 'inex-phone-screen-so-mednav' AND extra_log_type = 'sign_phone_screen_reviewer'
      OR :activity_outstanding = 'inex-phone-screen-so-staff' AND extra_log_type = 'sign_phone_screen_staff'
      OR :activity_outstanding = 'inex-tms-responses' AND extra_log_type = 'tms_responses'
      OR :activity_outstanding = 'inex-tms-so' AND extra_log_type = 'sign_tms_eligibility'
      OR :activity_outstanding = 'phone-screen-complete' AND extra_log_type = 'phone_screen_finalized'
      OR :activity_outstanding = 'has-planned-event' AND extra_log_type = 'planned_event'
      OR :activity_outstanding = 'has-event-feedback' AND extra_log_type = 'station_event'
      OR :activity_outstanding = 'appointment-set' AND extra_log_type='appointment'

      OR (
          :activity_outstanding = 'inex-baseline-complete'
          AND (
            extra_log_type IN ('sign_baseline') AND
            checklist_signed = 'yes'
          )
      )


      OR :activity_outstanding NOT IN ('inex-complete', 'phone-screen-complete') AND extra_log_type = :activity_outstanding
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
