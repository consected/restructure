
    -- Generate the table to hold recruitment ranks in the IPA schema
    SET search_path=ipa_ops;
    BEGIN;

      -- create table ipa_ops.subjects (id serial, master_id integer);
      -- insert into ipa_ops.subjects (master_id) (select id from ml_app.masters);


      -- Create a table for recruitment ranks, which will be viewed in the ml_app schema by Zeus
      CREATE TABLE ipa_recruitment_ranks (
          id SERIAL,
          master_id integer,
          rank integer
      );

      GRANT ALL ON ipa_ops.ipa_recruitment_ranks TO fphs;
      GRANT SELECT ON ipa_ops.ipa_recruitment_ranks TO fphsadm;

    COMMIT;

    -- Generate the views used by Zeus for access to IPA data
    SET search_path=ml_app;
    BEGIN;

      -- Create a view for the external identifiers configuration of IPA IDs
      create view ml_app.ipa_assignments as select id, master_id, id ipa_id, now() created_at, now() updated_at from ipa_ops.subjects;

      -- Create a view for IPA recruitment ranks
      create view ml_app.ipa_recruitment_ranks as select id, master_id, rank, now() created_at, now() updated_at from ipa_ops.ipa_recruitment_ranks;


      GRANT ALL ON ml_app.ipa_assignments TO fphs;
      GRANT SELECT ON ml_app.ipa_assignments TO fphsusr;
      GRANT SELECT ON ml_app.ipa_assignments TO fphsetl;
      GRANT SELECT ON ml_app.ipa_assignments TO fphsadm;

      GRANT ALL ON ml_app.ipa_recruitment_ranks TO fphs;
      GRANT SELECT ON ml_app.ipa_recruitment_ranks TO fphsusr;
      GRANT SELECT ON ml_app.ipa_recruitment_ranks TO fphsetl;
      GRANT SELECT ON ml_app.ipa_recruitment_ranks TO fphsadm;
    COMMIT;
