set search_path = ml_app, ipa_ops;
      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ipa_ps_healths false physical_limitations_blank_yes_no physical_limitations_details sit_back_blank_yes_no sit_back_details cycle_blank_yes_no cycle_details chronic_pain_blank_yes_no chronic_pain_details chronic_pain_meds_blank_yes_no_dont_know chronic_pain_meds_details hemophilia_blank_yes_no_dont_know hemophilia_details raynauds_syndrome_blank_yes_no_dont_know raynauds_syndrome_severity_selection raynauds_syndrome_details other_conditions_blank_yes_no_dont_know other_conditions_details hypertension_diagnosis_blank_yes_no_dont_know hypertension_diagnosis_details other_heart_conditions_blank_yes_no_dont_know other_heart_conditions_details memory_problems_blank_yes_no_dont_know memory_problems_details mental_health_conditions_blank_yes_no_dont_know mental_health_conditions_details neurological_problems_blank_yes_no_dont_know neurological_problems_details

      CREATE OR REPLACE FUNCTION log_ipa_ps_health_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_health_history
                  (
                      master_id,
                      physical_limitations_blank_yes_no,
                      physical_limitations_details,
                      sit_back_blank_yes_no,
                      sit_back_details,
                      cycle_blank_yes_no,
                      cycle_details,
                      chronic_pain_blank_yes_no,
                      chronic_pain_details,
                      chronic_pain_meds_blank_yes_no_dont_know,
                      chronic_pain_meds_details,
                      hemophilia_blank_yes_no_dont_know,
                      hemophilia_details,
                      raynauds_syndrome_blank_yes_no_dont_know,
                      raynauds_syndrome_severity_selection,
                      raynauds_syndrome_details,

                      hypertension_diagnosis_blank_yes_no_dont_know,
                      hypertension_diagnosis_details,

                      diabetes_diagnosis_blank_yes_no_dont_know,
                      diabetes_diagnosis_details,
                      high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      high_cholesterol_diagnosis_details,

                      other_heart_conditions_blank_yes_no_dont_know,
                      other_heart_conditions_details,

                      heart_surgeries_blank_yes_no_dont_know,
                      heart_surgeries_details,
                      caridiac_pacemaker_blank_yes_no_dont_know,
                      caridiac_pacemaker_details,

                      memory_problems_blank_yes_no_dont_know,
                      memory_problems_details,
                      mental_health_conditions_blank_yes_no_dont_know,
                      mental_health_conditions_details,

                      mental_health_help_blank_yes_no_dont_know,
                      mental_health_help_details,

                      neurological_problems_blank_yes_no_dont_know,
                      neurological_problems_details,

                      neurological_surgeries_blank_yes_no_dont_know,
                      neurological_surgeries_details,

                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_health_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.physical_limitations_blank_yes_no,
                      NEW.physical_limitations_details,
                      NEW.sit_back_blank_yes_no,
                      NEW.sit_back_details,
                      NEW.cycle_blank_yes_no,
                      NEW.cycle_details,
                      NEW.chronic_pain_blank_yes_no,
                      NEW.chronic_pain_details,
                      NEW.chronic_pain_meds_blank_yes_no_dont_know,
                      NEW.chronic_pain_meds_details,
                      NEW.hemophilia_blank_yes_no_dont_know,
                      NEW.hemophilia_details,
                      NEW.raynauds_syndrome_blank_yes_no_dont_know,
                      NEW.raynauds_syndrome_severity_selection,
                      NEW.raynauds_syndrome_details,

                      NEW.hypertension_diagnosis_blank_yes_no_dont_know,
                      NEW.hypertension_diagnosis_details,

                      NEW.diabetes_diagnosis_blank_yes_no_dont_know,
                      NEW.diabetes_diagnosis_details,
                      NEW.high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      NEW.high_cholesterol_diagnosis_details,

                      NEW.other_heart_conditions_blank_yes_no_dont_know,
                      NEW.other_heart_conditions_details,

                      NEW.heart_surgeries_blank_yes_no_dont_know,
                      NEW.heart_surgeries_details,
                      NEW.caridiac_pacemaker_blank_yes_no_dont_know,
                      NEW.caridiac_pacemaker_details,

                      NEW.memory_problems_blank_yes_no_dont_know,
                      NEW.memory_problems_details,
                      NEW.mental_health_conditions_blank_yes_no_dont_know,
                      NEW.mental_health_conditions_details,

                      NEW.mental_health_help_blank_yes_no_dont_know,
                      NEW.mental_health_help_details,

                      NEW.neurological_problems_blank_yes_no_dont_know,
                      NEW.neurological_problems_details,

                      NEW.neurological_surgeries_blank_yes_no_dont_know,
                      NEW.neurological_surgeries_details,

                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      ALTER TABLE ipa_ps_health_history
          drop column other_conditions_blank_yes_no_dont_know,
          drop column other_conditions_details,

          add column diabetes_diagnosis_blank_yes_no_dont_know varchar,
          add column diabetes_diagnosis_details varchar,
          add column high_cholesterol_diagnosis_blank_yes_no_dont_know varchar,
          add column high_cholesterol_diagnosis_details varchar,

          add column heart_surgeries_blank_yes_no_dont_know varchar,
          add column heart_surgeries_details varchar,
          add column caridiac_pacemaker_blank_yes_no_dont_know varchar,
          add column caridiac_pacemaker_details varchar,


          add column mental_health_help_blank_yes_no_dont_know varchar,
          add column mental_health_help_details varchar,

          add column neurological_surgeries_blank_yes_no_dont_know varchar,
          add column neurological_surgeries_details varchar
      ;


      ALTER TABLE ipa_ps_healths
        drop column other_conditions_blank_yes_no_dont_know,
        drop column other_conditions_details,

        add column diabetes_diagnosis_blank_yes_no_dont_know varchar,
        add column diabetes_diagnosis_details varchar,
        add column high_cholesterol_diagnosis_blank_yes_no_dont_know varchar,
        add column high_cholesterol_diagnosis_details varchar,

        add column heart_surgeries_blank_yes_no_dont_know varchar,
        add column heart_surgeries_details varchar,
        add column caridiac_pacemaker_blank_yes_no_dont_know varchar,
        add column caridiac_pacemaker_details varchar,


        add column mental_health_help_blank_yes_no_dont_know varchar,
        add column mental_health_help_details varchar,

        add column neurological_surgeries_blank_yes_no_dont_know varchar,
        add column neurological_surgeries_details varchar
      ;

      COMMIT;
