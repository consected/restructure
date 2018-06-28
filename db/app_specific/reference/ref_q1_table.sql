/*

  Reference only
  --------------

  Dump of schemas for q1 rc_copy and sc_copy tables.


*/

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = q1, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: rc_stage; Type: TABLE; Schema: q1; Owner: fphs; Tablespace:
--

CREATE TABLE rc_stage (
    record_id integer,
    redcap_survey_identifier integer,
    football_players_health_study_questionnaire_1_timestamp timestamp without time zone,
    dob date,
    age integer,
    race___1 integer,
    race___2 integer,
    race___3 integer,
    race___4 integer,
    race___5 integer,
    race___6 integer,
    race___7 integer,
    hispanic integer,
    domesticstatus integer,
    livingsituation integer,
    height integer,
    current_weight integer,
    highschool_wt integer,
    college_wt integer,
    pro_wt integer,
    maxretire_wt integer,
    startplay_age integer,
    numb_season double precision,
    first_cal_yearplay integer,
    last_cal_yearplay integer,
    position___1 integer,
    position___2 integer,
    position___3 integer,
    position___4 integer,
    position___5 integer,
    position___6 integer,
    position___7 integer,
    position___8 integer,
    position___9 integer,
    position___10 integer,
    global1 integer,
    global2 integer,
    global3 integer,
    global4 integer,
    global5 integer,
    global6 integer,
    global7 integer,
    global8 integer,
    global10 integer,
    phq1 integer,
    phq2 integer,
    gad1 integer,
    gad_2 integer,
    number_days_exercise integer,
    walking integer,
    jogging integer,
    running integer,
    other_aerobic integer,
    low_intensity_exercise integer,
    weight_training integer,
    promis_pf6b1 integer,
    promis_pf6b2 integer,
    promis_pf6b3 integer,
    promis_pf6b4 integer,
    promis_pf6b5 integer,
    promis_pf6b6 integer,
    painin3 integer,
    painin8 integer,
    painin9 integer,
    painin10 integer,
    painin14 integer,
    painin26 integer,
    nqcog64 integer,
    nqcog65 integer,
    nqcog66 integer,
    nqcog68 integer,
    nqcog72 integer,
    nqcog75 integer,
    nqcog77 integer,
    nqcog80 integer,
    nqcog67_editted integer,
    nqcog84 integer,
    nqcog86 integer,
    pcp integer,
    other_health_professional integer,
    supplement___1 integer,
    supplement___2 integer,
    supplement___3 integer,
    supplement___4 integer,
    medication___1 integer,
    medication___2 integer,
    medication___3 integer,
    medication___4 integer,
    pain_medications___1 integer,
    pain_medications___2 integer,
    pain_medications___3 integer,
    pain_medications___4 integer,
    dx_concussion integer,
    numb_concussions character varying(255),
    headaches_ht integer,
    nausea integer,
    dizziness integer,
    loss_of_consciousness integer,
    memory_problems integer,
    disorientation integer,
    confusion integer,
    seizure integer,
    visual_problems integer,
    weakness_on_one_side_of_th integer,
    feeling_unsteady_on_your_f integer,
    neck_surgery integer,
    back_surgery integer,
    anterior_cruciate_ligament integer,
    knee_surgery integer,
    ankle_surgery integer,
    shoulder_surgery integer,
    hand_surgery integer,
    knee_joint_replacement integer,
    approxyrssurg_knee character varying(255),
    hip_joint_replacemen integer,
    approxyrssurg_hip character varying(255),
    cardiac_surgery integer,
    approxyrssurg_cardiac character varying(255),
    cataract_surgery integer,
    approxyrssurg_cataract character varying(255),
    neck_spine_surgery integer,
    approxyrssurg_neckspine character varying(255),
    back_surgery1 integer,
    approxyrssurg_back character varying(255),
    othersurgery integer,
    type_other_surgery character varying(255),
    years_other_surgery character varying(255),
    high_blood_pressure integer,
    current_htn_med integer,
    heart_failure integer,
    current_heartfailure_med integer,
    heart_rhythm integer,
    current_heartrhythm_med integer,
    high_cholesterol integer,
    current_highcholesterol integer,
    diabetes_high_blood_sugar integer,
    current_diabetes_med integer,
    headaches integer,
    current_headache_med integer,
    pain_medication integer,
    current_medication_pain integer,
    liver_probelm integer,
    current_med_liver_problem integer,
    anxiety integer,
    current_anxiety_med integer,
    depression integer,
    current_depression_med integer,
    memory_loss integer,
    current_med_memory_loss integer,
    add integer,
    current_med_add integer,
    low_testosterone integer,
    current_lowt_med integer,
    erectile_dys integer,
    current_erectile_dys integer,
    heart_attack integer,
    yr_dx_heart_attack character varying(255),
    stroke integer,
    yr_dx_stroke character varying(255),
    sleep_apnea integer,
    yr_dx_sleepapnea character varying(255),
    dementia integer,
    yr_dx_dementia character varying(255),
    cte integer,
    yr_dx_cte character varying(255),
    parkinsons integer,
    yr_dx_parkinsons character varying(255),
    arthritis integer,
    yr_dx_arthritis character varying(255),
    als integer,
    yr_dx_als character varying(255),
    renal_kidney_disease integer,
    yr_dx_kidney_dx character varying(255),
    cancer integer,
    cancer_type character varying(255),
    yr_dx_cancer character varying(255),
    days_drink_week integer,
    drinksday integer,
    smoking_hx integer,
    do_you_currently_or_have_y integer,
    snore_loudly integer,
    sleephrs integer,
    health_expectation integer,
    are_you_currently_employed integer,
    student_looking integer,
    job_in_football integer,
    other_job_in_football character varying(255),
    job_industry character varying(255),
    job_outside_football character varying(255),
    retired_industry character varying(255),
    retired_job_title character varying(255),
    questionnaire_help integer,
    football_players_health_study_questionnaire_1_complete integer
);


ALTER TABLE rc_stage OWNER TO fphs;

--
-- Name: rc_stage; Type: ACL; Schema: q1; Owner: fphs
--

REVOKE ALL ON TABLE rc_stage FROM PUBLIC;
REVOKE ALL ON TABLE rc_stage FROM fphs;
GRANT ALL ON TABLE rc_stage TO fphs;
GRANT SELECT,INSERT,UPDATE ON TABLE rc_stage TO fphsusr;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE rc_stage TO fphsadm;
GRANT SELECT ON TABLE rc_stage TO czm39;
GRANT SELECT ON TABLE rc_stage TO cmm61;
GRANT SELECT ON TABLE rc_stage TO rgg15;


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = q1, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: sc_stage; Type: TABLE; Schema: q1; Owner: fphs; Tablespace:
--

CREATE TABLE sc_stage (
    ncs_header character varying(100),
    litho integer,
    opp_date date,
    dob date,
    age integer,
    race___1 integer,
    race___2 integer,
    race___3 integer,
    race___4 integer,
    race___5 integer,
    race___6 integer,
    hispanic integer,
    domesticstatus integer,
    livingsituation integer,
    feet integer,
    inches integer,
    current_weight integer,
    highschool_wt integer,
    college_wt integer,
    pro_wt integer,
    maxretire_wt integer,
    startplay_age integer,
    numb_season double precision,
    first_cal_yearplay integer,
    last_cal_yearplay integer,
    position___1 integer,
    position___2 integer,
    position___3 integer,
    position___4 integer,
    position___5 integer,
    position___6 integer,
    position___7 integer,
    position___8 integer,
    position___9 integer,
    position___10 integer,
    global1 integer,
    global2 integer,
    global3 integer,
    global4 integer,
    global5 integer,
    global6 integer,
    global7 integer,
    global8 integer,
    global10 integer,
    phq1 integer,
    phq2 integer,
    gad1 integer,
    gad_2 integer,
    number_days_exercise integer,
    walking integer,
    jogging integer,
    running integer,
    other_aerobic integer,
    low_intensity_exercise integer,
    weight_training integer,
    promis_pf6b1 integer,
    promis_pf6b2 integer,
    promis_pf6b3 integer,
    promis_pf6b4 integer,
    promis_pf6b5 integer,
    promis_pf6b6 integer,
    painin3 integer,
    painin8 integer,
    painin9 integer,
    painin10 integer,
    painin14 integer,
    painin26 integer,
    nqcog64 integer,
    nqcog65 integer,
    nqcog66 integer,
    nqcog68 integer,
    nqcog72 integer,
    nqcog75 integer,
    nqcog77 integer,
    nqcog80 integer,
    nqcog67_editted integer,
    nqcog84 integer,
    nqcog86 integer,
    pcp integer,
    other_health_professional integer,
    supplement___1 integer,
    supplement___2 integer,
    supplement___3 integer,
    supplement___4 integer,
    medication___1 integer,
    medication___2 integer,
    medication___3 integer,
    medication___4 integer,
    pain_medications___1 integer,
    pain_medications___2 integer,
    pain_medications___3 integer,
    pain_medications___4 integer,
    dx_concussion integer,
    numb_concussions character varying(255),
    headaches_ht integer,
    nausea integer,
    dizziness integer,
    loss_of_consciousness integer,
    memory_problems integer,
    disorientation integer,
    confusion integer,
    seizure integer,
    visual_problems integer,
    weakness_on_one_side_of_th integer,
    feeling_unsteady_on_your_f integer,
    neck_surgery integer,
    back_surgery integer,
    anterior_cruciate_ligament integer,
    knee_surgery integer,
    ankle_surgery integer,
    shoulder_surgery integer,
    hand_surgery integer,
    knee_joint_replacement integer,
    approxyrssurg_knee character varying(255),
    hip_joint_replacemen integer,
    approxyrssurg_hip character varying(255),
    cardiac_surgery integer,
    approxyrssurg_cardiac character varying(255),
    cataract_surgery integer,
    approxyrssurg_cataract character varying(255),
    neck_spine_surgery integer,
    approxyrssurg_neckspine character varying(255),
    back_surgery1 integer,
    approxyrssurg_back character varying(255),
    othersurgery integer,
    type_other_surgery character varying(255),
    operator65 integer,
    years_other_surgery character varying(255),
    high_blood_pressure integer,
    current_htn_med integer,
    heart_failure integer,
    current_heartfailure_med integer,
    heart_rhythm integer,
    current_heartrhythm_med integer,
    high_cholesterol integer,
    current_highcholesterol integer,
    diabetes_high_blood_sugar integer,
    current_diabetes_med integer,
    headaches integer,
    current_headache_med integer,
    pain_medication integer,
    current_medication_pain integer,
    liver_problem integer,
    current_med_liver_problem integer,
    anxiety integer,
    current_anxiety_med integer,
    depression integer,
    current_depression_med integer,
    memory_loss integer,
    current_med_memory_loss integer,
    add integer,
    current_med_add integer,
    low_testosterone integer,
    current_lowt_med integer,
    erectile_dys integer,
    current_erectile_dys integer,
    heart_attack integer,
    yr_dx_heart_attack character varying(255),
    stroke integer,
    yr_dx_stroke character varying(255),
    sleep_apnea integer,
    yr_dx_sleepapnea character varying(255),
    dementia integer,
    yr_dx_dementia character varying(255),
    cte integer,
    yr_dx_cte character varying(255),
    parkinsons integer,
    yr_dx_parkinsons character varying(255),
    arthritis integer,
    yr_dx_arthritis character varying(255),
    als integer,
    yr_dx_als character varying(255),
    renal_kidney_disease integer,
    yr_dx_kidney_dx character varying(255),
    cancer integer,
    cancer_type character varying(255),
    operator67 integer,
    yr_dx_cancer character varying(255),
    days_drink_week integer,
    drinksday integer,
    smoking_hx integer,
    do_you_currently_or_have_y integer,
    snore_loudly integer,
    sleephrs integer,
    health_expectation integer,
    are_you_currently_employed integer,
    student_looking integer,
    job_in_football integer,
    other_job_in_football character varying(255),
    job_industry character varying(255),
    job_outside_football character varying(255),
    job_outside_ses character varying(255),
    retired_industry character varying(255),
    retired_job_title character varying(255),
    retired_ses character varying(255),
    operator75 integer,
    questionnaire_help integer,
    msid integer
);


ALTER TABLE sc_stage OWNER TO fphs;

--
-- Name: sc_stage; Type: ACL; Schema: q1; Owner: fphs
--

REVOKE ALL ON TABLE sc_stage FROM PUBLIC;
REVOKE ALL ON TABLE sc_stage FROM fphs;
GRANT ALL ON TABLE sc_stage TO fphs;
GRANT SELECT,INSERT,UPDATE ON TABLE sc_stage TO fphsusr;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sc_stage TO fphsadm;
GRANT SELECT ON TABLE sc_stage TO czm39;
GRANT SELECT ON TABLE sc_stage TO cmm61;
GRANT SELECT ON TABLE sc_stage TO rgg15;


--
-- PostgreSQL database dump complete
--
