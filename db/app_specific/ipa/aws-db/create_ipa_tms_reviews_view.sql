BEGIN;

CREATE OR REPLACE VIEW ipa_ops.ipa_tms_reviews AS
WITH tms AS (
  SELECT
    rank() OVER (PARTITION BY master_id ORDER BY id DESC) r,
    *
  FROM ipa_ops.ipa_ps_tms_tests
),
mri AS (
  SELECT
    rank() OVER (PARTITION BY master_id ORDER BY id DESC) r,
    *
  FROM ipa_ops.ipa_ps_mris
),
health AS (
  SELECT
    rank() OVER (PARTITION BY master_id ORDER BY id DESC) r,
    *
  FROM ipa_ops.ipa_ps_healths
)
SELECT
  tms.id,
  tms.master_id,
  tms.user_id,
  tms.created_at,
  tms.updated_at,
  tms.past_tms_blank_yes_no_dont_know,
  tms.past_tms_details,
  tms.convulsion_or_seizure_blank_yes_no_dont_know,
  tms.convulsion_or_seizure_details,
  tms.epilepsy_blank_yes_no_dont_know,
  tms.epilepsy_details,
  tms.fainting_blank_yes_no_dont_know,
  tms.fainting_details,
  tms.concussion_blank_yes_no_dont_know,
  tms.loss_of_conciousness_details,
  tms.hairstyle_scalp_blank_yes_no_dont_know,
  tms.hairstyle_scalp_details,
  tms.hearing_problems_blank_yes_no_dont_know,
  tms.cochlear_implants_blank_yes_no_dont_know,
  tms.neurostimulator_blank_yes_no_dont_know,
  tms.neurostimulator_details,
  tms.med_infusion_device_blank_yes_no_dont_know,
  tms.med_infusion_device_details,
  tms.metal_blank_yes_no_dont_know,
  tms.metal_details,
  tms.current_meds_blank_yes_no_dont_know,
  tms.current_meds_details,
  mri.past_mri_yes_no_dont_know,
  mri.past_mri_details,
  --mri.metal_implants_blank_yes_no_dont_know,
  mri.metal_implants_details,
  mri.electrical_implants_blank_yes_no_dont_know,
  mri.electrical_implants_details,
  mri.metal_jewelry_blank_yes_no,
  mri.hearing_aid_blank_yes_no,
  health.caridiac_pacemaker_blank_yes_no_dont_know,
  health.caridiac_pacemaker_details
FROM
  tms
  JOIN mri ON tms.master_id = mri.master_id
  JOIN health ON tms.master_id = health.master_id
WHERE
  tms.r = 1
  AND health.r = 1
  AND mri.r = 1;

GRANT SELECT ON ipa_ops.ipa_tms_reviews TO fphs;

GRANT SELECT ON ipa_ops.ipa_tms_reviews TO fphsusr;

GRANT SELECT ON ipa_ops.ipa_tms_reviews TO fphsadm;

GRANT SELECT ON ipa_ops.ipa_tms_reviews TO fphsrailsapp;

END;

