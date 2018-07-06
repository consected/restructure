
    SET search_path=ipa_ops;
    BEGIN;

      -- Create a table for recruitment ranks, which will be viewed in the ml_app schema by Zeus
      CREATE TABLE ipa_recruitment_ranks (
          id SERIAL,
          master_id integer,
          rank integer
      );

    COMMIT;

    -- Generate the views used by Zeus for access to IPA data
    SET search_path=ml_app;
    BEGIN;

      -- Create a view for IPA IDs
      -- ??????????????????????????????????????????? IS THIS VIEWING THE CORRECT TABLE ??????????????????????????????????????????
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
