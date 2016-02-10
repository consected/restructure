-- Script created @ 2016-02-10 12:59:22 -0500
set search_path=ml_app; 
 begin;  ;
    
  DROP TRIGGER IF EXISTS address_update on addresses;
  DROP TRIGGER IF EXISTS address_insert on addresses;
  DROP FUNCTION IF EXISTS handle_address_update();
  CREATE FUNCTION handle_address_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          
          NEW.street := lower(NEW.street);
          NEW.street2 := lower(NEW.street2);
          NEW.street3 := lower(NEW.street3);
          NEW.city := lower(NEW.city);
          NEW.state := lower(NEW.state);
          NEW.zip := lower(NEW.zip);
          NEW.country := lower(NEW.country);
          NEW.postal_code := lower(NEW.postal_code);
          NEW.region := lower(NEW.region);
          NEW.source := lower(NEW.source);
          RETURN NEW;
            
        END;   
    $$;
    
    CREATE TRIGGER address_update BEFORE UPDATE ON addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_address_update();
    CREATE TRIGGER address_insert BEFORE INSERT ON addresses FOR EACH ROW EXECUTE PROCEDURE handle_address_update();


  DROP FUNCTION IF EXISTS update_address_ranks(set_master_id INTEGER);
  CREATE FUNCTION update_address_ranks(set_master_id INTEGER) RETURNS INTEGER
    LANGUAGE plpgsql
    AS $$
        DECLARE
          latest_primary RECORD;
        BEGIN
  
          SELECT * into latest_primary 
          FROM addresses
          WHERE master_id = set_master_id
          AND rank = 10
          ORDER BY updated_at DESC
          LIMIT 1;
        
          IF NOT FOUND THEN
            RETURN NULL;
          END IF;

          
          UPDATE addresses SET rank = 5 
          WHERE 
            master_id = set_master_id 
            AND rank = 10
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$;



;
    
  DROP TRIGGER IF EXISTS player_contact_update on player_contacts;
  DROP TRIGGER IF EXISTS player_contact_insert on player_contacts;
  DROP FUNCTION IF EXISTS handle_player_contact_update();
  CREATE FUNCTION handle_player_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
         

          NEW.rec_type := lower(NEW.rec_type);
          NEW.data := lower(NEW.data);
          NEW.source := lower(NEW.source);


          RETURN NEW;
            
        END;   
    $$;
    
    CREATE TRIGGER player_contact_update BEFORE UPDATE ON player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_player_contact_update();
    CREATE TRIGGER player_contact_insert BEFORE INSERT ON player_contacts FOR EACH ROW EXECUTE PROCEDURE handle_player_contact_update();



  DROP FUNCTION IF EXISTS update_player_contact_ranks(set_master_id INTEGER, set_rec_type VARCHAR);
  CREATE FUNCTION update_player_contact_ranks(set_master_id INTEGER, set_rec_type VARCHAR) RETURNS INTEGER
    LANGUAGE plpgsql
    AS $$
        DECLARE
          latest_primary RECORD;
        BEGIN
  
          SELECT * into latest_primary 
          FROM player_contacts
          WHERE master_id = set_master_id
          AND rank = 10
          AND rec_type = set_rec_type
          ORDER BY updated_at DESC
          LIMIT 1;
        
          IF NOT FOUND THEN
            RETURN NULL;
          END IF;

          
          UPDATE player_contacts SET rank = 5 
          WHERE 
            master_id = set_master_id 
            AND rank = 10
            AND rec_type = set_rec_type
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$;

;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSADM;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
SET search_path = ml_app, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20160210200918
20160210200919
\.

 commit; ;
