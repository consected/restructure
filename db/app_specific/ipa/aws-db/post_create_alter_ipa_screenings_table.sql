begin;

  alter table ipa_screenings
  add column good_time_to_speak_blank_yes_no varchar,
  add column callback_date date,
  add column callback_time time,
  add column still_interested_blank_yes_no varchar;

  alter table ipa_screening_history
  add column good_time_to_speak_blank_yes_no varchar,
  add column callback_date date,
  add column callback_time time,
  add column still_interested_blank_yes_no varchar;

  alter table ipa_screenings
  add column not_interested_notes varchar,
  add column ineligible_notes varchar,
  add column eligible_notes varchar;


  alter table ipa_screening_history
  add column not_interested_notes varchar,
  add column ineligible_notes varchar,
  add column eligible_notes varchar;



  CREATE OR REPLACE FUNCTION log_ipa_screening_update() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
          BEGIN
              INSERT INTO ipa_screening_history
              (
                  master_id,
                  eligible_for_study_blank_yes_no,
                  good_time_to_speak_blank_yes_no,
                  callback_date,
                  callback_time,
                  still_interested_blank_yes_no,
                  ineligible_notes,
                  eligible_notes,
                  not_interested_notes,
                  notes,
                  user_id,
                  created_at,
                  updated_at,
                  ipa_screening_id
                  )
              SELECT
                  NEW.master_id,
                  NEW.eligible_for_study_blank_yes_no,
                  NEW.good_time_to_speak_blank_yes_no,
                  NEW.callback_date,
                  NEW.callback_time,
                  NEW.still_interested_blank_yes_no,
                  NEW.ineligible_notes,
                  NEW.eligible_notes,
                  NEW.not_interested_notes,
                  NEW.notes,
                  NEW.user_id,
                  NEW.created_at,
                  NEW.updated_at,
                  NEW.id
              ;
              RETURN NEW;
          END;
      $$;

commit;
