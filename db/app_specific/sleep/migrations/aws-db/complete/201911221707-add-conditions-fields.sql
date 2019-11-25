set search_path=sleep, ml_app;
begin;

CREATE or REPLACE FUNCTION log_sleep_ps_basic_response_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO sleep_ps_basic_response_history
            (
                master_id,
                reliable_internet_yes_no,
                placeholder_digital_no,
                conditions_yes_no,
                conditions_notes,
                cbt_yes_no,
                cbt_how_long_ago,
                cbt_notes,
                sleep_times_yes_no,
                sleep_times_notes,
                work_night_shifts_yes_no,
                number_times_per_week_work_night_shifts,
                narcolepsy_diagnosis_yes_no_dont_know,
                narcolepsy_diagnosis_notes,
                antiseizure_meds_yes_no,
                seizure_in_ten_years_yes_no,
                major_psychiatric_disorder_yes_no,
                possibly_eligible_yes_no,
                possibly_eligible_reason_notes,
                notes,
                user_id,
                created_at,
                updated_at,
                sleep_ps_basic_response_id
                )
            SELECT
                NEW.master_id,
                NEW.reliable_internet_yes_no,
                NEW.placeholder_digital_no,
                NEW.conditions_yes_no,
                NEW.conditions_notes,
                NEW.cbt_yes_no,
                NEW.cbt_how_long_ago,
                NEW.cbt_notes,
                NEW.sleep_times_yes_no,
                NEW.sleep_times_notes,
                NEW.work_night_shifts_yes_no,
                NEW.number_times_per_week_work_night_shifts,
                NEW.narcolepsy_diagnosis_yes_no_dont_know,
                NEW.narcolepsy_diagnosis_notes,
                NEW.antiseizure_meds_yes_no,
                NEW.seizure_in_ten_years_yes_no,
                NEW.major_psychiatric_disorder_yes_no,
                NEW.possibly_eligible_yes_no,
                NEW.possibly_eligible_reason_notes,
                NEW.notes,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

    alter table sleep_ps_basic_response_history
    add column conditions_yes_no varchar,
    add column conditions_notes varchar
    ;

    alter table sleep_ps_basic_responses
    add column conditions_yes_no varchar,
    add column conditions_notes varchar
    ;

    CREATE or REPLACE FUNCTION log_sleep_inex_checklist_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO sleep_inex_checklist_history
                (
                    master_id,
                    fixed_checklist_type,
                    reliable_internet_yes_no,
                    conditions_yes_no,
                    cbt_yes_no,
                    cbt_how_long_ago,
                    sleep_times_yes_no,
                    work_night_shifts_yes_no,
                    number_times_per_week_work_night_shifts,
                    narcolepsy_diagnosis_yes_no_dont_know,
                    antiseizure_meds_yes_no,
                    seizure_in_ten_years_yes_no,
                    major_psychiatric_disorder_yes_no,
                    isi_total_score,
                    sa_diagnosed_yes_no,
                    sa_use_treatment_yes_no,
                    sa_severity,
                    ese_total_score,
                    number_hours_sleep,
                    audit_c_total_score,
                    alcohol_frequency,
                    number_days_negative_feeling_d2,
                    number_days_drug_usage_d2,
                    phq8_initial_score,
                    phq8_total_score,
                    consent_to_pass_info_to_bwh_yes_no,
                    select_subject_eligibility,
                    user_id,
                    created_at,
                    updated_at,
                    sleep_inex_checklist_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.fixed_checklist_type,
                    NEW.reliable_internet_yes_no,
                    NEW.conditions_yes_no,
                    NEW.cbt_yes_no,
                    NEW.cbt_how_long_ago,
                    NEW.sleep_times_yes_no,
                    NEW.work_night_shifts_yes_no,
                    NEW.number_times_per_week_work_night_shifts,
                    NEW.narcolepsy_diagnosis_yes_no_dont_know,
                    NEW.antiseizure_meds_yes_no,
                    NEW.seizure_in_ten_years_yes_no,
                    NEW.major_psychiatric_disorder_yes_no,
                    NEW.isi_total_score,
                    NEW.sa_diagnosed_yes_no,
                    NEW.sa_use_treatment_yes_no,
                    NEW.sa_severity,
                    NEW.ese_total_score,
                    NEW.number_hours_sleep,
                    NEW.audit_c_total_score,
                    NEW.alcohol_frequency,
                    NEW.number_days_negative_feeling_d2,
                    NEW.number_days_drug_usage_d2,
                    NEW.phq8_initial_score,
                    NEW.phq8_total_score,
                    NEW.consent_to_pass_info_to_bwh_yes_no,
                    NEW.select_subject_eligibility,
                    NEW.user_id,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;

        alter table sleep_inex_checklist_history
        add column conditions_yes_no varchar;

        alter table sleep_inex_checklists
        add column conditions_yes_no varchar;
end;
