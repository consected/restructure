set search_path=ipa_ops, ml_app;


    -- Get the latest subject size record
    SELECT *,
    extract(YEAR from age(birth_date)) age
    INTO subject_size
    FROM ipa_ps_sizes
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest MRI record
    SELECT *
    INTO mri
    FROM ipa_ps_mris
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest TMS record
    SELECT *
    INTO tms
    FROM ipa_ps_tms_tests
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest sleep record
    SELECT *
    INTO sleep
    FROM ipa_ps_sleeps
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest health record
    SELECT *
    INTO health
    FROM ipa_ps_healths
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest tmoca record
    SELECT *
    INTO tmoca
    FROM ipa_ps_tmocas
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the Player Info record
    SELECT *
    INTO player_info
    FROM player_infos
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;


    INSERT INTO ipa_medicine_details
    (
      master_id,
      created_at,
      updated_at,
      user_id,


    )

    VALUES
    (
      NEW.master_id,
      NOW(),
      NOW(),
      NEW.user_id,
    );
