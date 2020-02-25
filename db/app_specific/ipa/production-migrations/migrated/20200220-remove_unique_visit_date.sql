set search_path=ml_app, ipa_ops;


alter TABLE ipa_appointments
drop constraint ipa_appointments_visit_start_date_key;
