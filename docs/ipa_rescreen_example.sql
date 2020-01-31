SET search_path=ml_app, ipa_ops;


select id, extra_log_type from activity_log_ipa_assignment_inex_checklists where master_id = ${MASTER_ID} and extra_log_type in ('phone_screen_review', 'tms_responses');
-- update activity_log_ipa_assignment_inex_checklists set master_id = ${MASTER_ID} where master_id = ${MASTER_ID} and id in (249, 251);


select id, to_record_id from model_references
where from_record_master_id = ${MASTER_ID} and from_record_type='ActivityLog::IpaAssignmentInexChecklist' and to_record_type = 'DynamicModel::IpaInexChecklist';

select id, to_record_id from model_references
where from_record_master_id = ${MASTER_ID} and from_record_type='ActivityLog::IpaAssignmentPhoneScreen' and to_record_type = 'DynamicModel::IpaPsTmsTest';

-- update model_references set from_record_master_id = -1, to_record_master_id = 1 where from_record_master_id = ${MASTER_ID} and id in (8150455, 8150453);

select * from ipa_ps_tms_tests where master_id = ${MASTER_ID} and id = 28;
-- update ipa_ps_tms_tests set master_id = -1 where master_id = ${MASTER_ID} and id = 28;

select * from ipa_inex_checklists where master_id = ${MASTER_ID} and id = 26;
-- update ipa_inex_checklists set master_id = -1 where master_id = ${MASTER_ID} and id = 26;
