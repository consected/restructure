set search_path=ipa_ops, ml_app;

BEGIN;

  drop view ipa_ops.ipa_tms_reviews;

  create view ipa_ops.ipa_tms_reviews
  as select
    tms.id,
    tms.master_id,
    tms.user_id,
    tms.created_at,
    tms.updated_at,
    past_tms_blank_yes_no_dont_know,
    past_tms_details,
    convulsion_or_seizure_blank_yes_no_dont_know,
    convulsion_or_seizure_details,
    epilepsy_blank_yes_no_dont_know,
    epilepsy_details,
    fainting_blank_yes_no_dont_know,
    fainting_details,
    concussion_blank_yes_no_dont_know,
    loss_of_conciousness_details,
    hairstyle_scalp_blank_yes_no_dont_know,
    hairstyle_scalp_details,
    hearing_problems_blank_yes_no_dont_know,
    cochlear_implants_blank_yes_no_dont_know,
    neurostimulator_blank_yes_no_dont_know,
    neurostimulator_details,
    med_infusion_device_blank_yes_no_dont_know,
    med_infusion_device_details,
    metal_blank_yes_no_dont_know,
    metal_details,
    current_meds_blank_yes_no_dont_know,
    current_meds_details,
    past_mri_yes_no_dont_know,
    past_mri_details,
    metal_implants_blank_yes_no_dont_know,
    metal_implants_details,
    electrical_implants_blank_yes_no_dont_know,
    electrical_implants_details,
    metal_jewelry_blank_yes_no,
    hearing_aid_blank_yes_no,
    caridiac_pacemaker_blank_yes_no_dont_know,
    caridiac_pacemaker_details
  from
    ipa_ps_tms_tests tms
  inner join
    ipa_ps_mris mri
  on tms.master_id = mri.master_id
  inner join
    ipa_ps_healths health
  on tms.master_id = health.master_id;


  GRANT SELECT ON ipa_ops.ipa_tms_reviews TO fphs;
  GRANT SELECT ON ipa_ops.ipa_tms_reviews TO fphsusr;
  GRANT SELECT ON ipa_ops.ipa_tms_reviews TO fphsadm;
  GRANT SELECT ON ipa_ops.ipa_tms_reviews TO fphsrailsapp;

END;
