-- Handle provide a view to allow comparison of ages at the time Q1 was completed
-- Update the recruitment ranks view to show if the player is eligible for IPA based on his
-- player info age when Q1 was completed

    BEGIN;

      -- Create a view for the various ages from q1 and ml_app, and calculate if they are eligible for IPA
      -- Since the Q1 reported dob and ml_app reported birth_date may not match, generate the view with all the
      -- possible options. We expect that the ml_app.player_infos.birth_date is the most accurate since it has
      -- been validated by FPHS staff (at least for validated players)
      create view ipa_ops.q1_ages
      as
      select
          m.id master_id,
          surveys.*,
          pi.birth_date ml_app_dob,
          q1_dob::date = pi.birth_date::date q1_ml_app_dob_match,
          extract(YEAR from age(q1_date, q1_dob))::integer q1_calc_age,
          extract(YEAR from age(q1_date, pi.birth_date))::integer ml_app_calc_age,
          extract(YEAR from age(q1_date, q1_dob)) BETWEEN 24 AND 55 q1_age_eligible_for_ipa,
          extract(YEAR from age(q1_date, pi.birth_date)) BETWEEN 24 AND 55 ml_app_age_eligible_for_ipa
      from ml_app.masters m
      inner join ml_app.player_infos pi
        on pi.master_id = m.id
      inner join (
          select
            msid,
            opp_date q1_date,
            dob q1_dob,
            age q1_age
          from q1.sc_stage
          union
          select
            redcap_survey_identifier msid,
            football_players_health_study_questionnaire_1_timestamp q1_date,
            dob q1_dob,
            age q1_age
          from q1.rc_stage
      ) surveys
      on m.msid = surveys.msid;

      GRANT ALL ON ipa_ops.q1_ages TO fphs;
      GRANT SELECT ON ipa_ops.q1_ages TO fphsadm;



      -- Alter view for IPA recruitment ranks
      drop view ml_app.ipa_recruitment_ranks;
      create view ml_app.ipa_recruitment_ranks as
        select
          a.id,
          m.id "master_id",
          sleep_apnea + pain + neurocognitive + cardiometabolic "afflictions",
          age between 24 and 55 "age_eligible",
          q2_eligible, black # white "black_or_white",
          coalesce((sleep_apnea + pain + neurocognitive + cardiometabolic <> 2) AND (age between 24 and 55) AND q2_eligible = 1 AND (black # white = 1), false) "eligible",
          now() created_at,
          now() updated_at
        from ml_app.masters m
        left join ipa_athena.afflictions a
        on m.msid = a.msid
      ;

      GRANT ALL ON ml_app.ipa_recruitment_ranks TO fphs;
      GRANT SELECT ON ml_app.ipa_recruitment_ranks TO fphsusr;
      GRANT SELECT ON ml_app.ipa_recruitment_ranks TO fphsetl;
      GRANT SELECT ON ml_app.ipa_recruitment_ranks TO fphsadm;

    COMMIT;
