set search_path = ipa_ops;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_ps_informant_details informant_name relationship_to_participant contact_information_notes

  CREATE or REPLACE FUNCTION log_ipa_ps_informant_detail_update() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
          BEGIN
              INSERT INTO ipa_ps_informant_detail_history
              (
                  master_id,
                  first_name,
                  last_name,
                  email,
                  phone,
                  relationship_to_participant,
                  contact_information_notes,
                  user_id,
                  created_at,
                  updated_at,
                  ipa_ps_informant_detail_id
                  )
              SELECT
                  NEW.master_id,
                  NEW.first_name,
                  NEW.last_name,
                  NEW.email,
                  NEW.phone,
                  NEW.relationship_to_participant,
                  NEW.contact_information_notes,
                  NEW.user_id,
                  NEW.created_at,
                  NEW.updated_at,
                  NEW.id
              ;
              RETURN NEW;
          END;
      $$;

      alter TABLE ipa_ps_informant_detail_history
          rename column informant_name to last_name
      ;

      alter TABLE ipa_ps_informant_details
          rename column informant_name to last_name
      ;

      alter TABLE ipa_ps_informant_detail_history
        add column first_name varchar,
        add column email varchar,
        add column phone varchar
      ;

      alter TABLE ipa_ps_informant_details
        add column first_name varchar,
        add column email varchar,
        add column phone varchar
      ;

      COMMIT;
