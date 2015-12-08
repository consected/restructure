class DataDowncaseAddress < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
# Enhance the trackers trigger writing to tracker_history for insert and update
execute <<EOF
    
  DROP TRIGGER IF EXISTS address_update on addresses;
  DROP TRIGGER IF EXISTS address_insert on addresses;
  DROP FUNCTION IF EXISTS handle_address_update();
  CREATE FUNCTION handle_address_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          
          IF NEW.rank = 10 AND NEW.master_id IS NOT NULL THEN
            UPDATE addresses SET rank = 5 
            WHERE master_id = NEW.master_id AND rank = 10;

          END IF;

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

EOF
        end
        dir.down do
execute <<EOF

  
  DROP TRIGGER IF EXISTS address_update on addresses;
  DROP TRIGGER IF EXISTS address_insert on addresses;
  DROP FUNCTION IF EXISTS handle_address_update();

EOF
      end
    end
  end
end
