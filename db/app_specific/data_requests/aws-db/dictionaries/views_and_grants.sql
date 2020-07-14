create view ml_app.q2_datadic as 
select * from q2.q2_datadic;

create view ml_app.ipa_datadic as 
select * from ipa_ops.ipa_datadic;


GRANT DELETE ON ml_app.q2_datadic TO fphsusr;
GRANT INSERT ON ml_app.q2_datadic TO fphsusr;
GRANT SELECT ON ml_app.q2_datadic TO fphsusr;
GRANT UPDATE ON ml_app.q2_datadic TO fphsusr;
GRANT DELETE ON ml_app.q2_datadic TO fphsrailsapp;
GRANT INSERT ON ml_app.q2_datadic TO fphsrailsapp;
GRANT SELECT ON ml_app.q2_datadic TO fphsrailsapp;
GRANT UPDATE ON ml_app.q2_datadic TO fphsrailsapp;
GRANT DELETE ON ml_app.q2_datadic TO fphsrailsapp1;
GRANT INSERT ON ml_app.q2_datadic TO fphsrailsapp1;
GRANT SELECT ON ml_app.q2_datadic TO fphsrailsapp1;
GRANT UPDATE ON ml_app.q2_datadic TO fphsrailsapp1;
GRANT DELETE ON ml_app.q2_datadic TO fphsadm;
GRANT INSERT ON ml_app.q2_datadic TO fphsadm;
GRANT SELECT ON ml_app.q2_datadic TO fphsadm;
GRANT UPDATE ON ml_app.q2_datadic TO fphsadm;
GRANT DELETE ON ml_app.q2_datadic TO fphsetl;
GRANT INSERT ON ml_app.q2_datadic TO fphsetl;
GRANT SELECT ON ml_app.q2_datadic TO fphsetl;
GRANT UPDATE ON ml_app.q2_datadic TO fphsetl;

GRANT DELETE ON ml_app.ipa_datadic TO fphsusr;
GRANT INSERT ON ml_app.ipa_datadic TO fphsusr;
GRANT SELECT ON ml_app.ipa_datadic TO fphsusr;
GRANT UPDATE ON ml_app.ipa_datadic TO fphsusr;
GRANT DELETE ON ml_app.ipa_datadic TO fphsrailsapp;
GRANT INSERT ON ml_app.ipa_datadic TO fphsrailsapp;
GRANT SELECT ON ml_app.ipa_datadic TO fphsrailsapp;
GRANT UPDATE ON ml_app.ipa_datadic TO fphsrailsapp;
GRANT DELETE ON ml_app.ipa_datadic TO fphsrailsapp1;
GRANT INSERT ON ml_app.ipa_datadic TO fphsrailsapp1;
GRANT SELECT ON ml_app.ipa_datadic TO fphsrailsapp1;
GRANT UPDATE ON ml_app.ipa_datadic TO fphsrailsapp1;
GRANT DELETE ON ml_app.ipa_datadic TO fphsadm;
GRANT INSERT ON ml_app.ipa_datadic TO fphsadm;
GRANT SELECT ON ml_app.ipa_datadic TO fphsadm;
GRANT UPDATE ON ml_app.ipa_datadic TO fphsadm;
GRANT DELETE ON ml_app.ipa_datadic TO fphsetl;
GRANT INSERT ON ml_app.ipa_datadic TO fphsetl;
GRANT SELECT ON ml_app.ipa_datadic TO fphsetl;
GRANT UPDATE ON ml_app.ipa_datadic TO fphsetl;
