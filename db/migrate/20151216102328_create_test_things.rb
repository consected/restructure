class CreateTestThings < ActiveRecord::Migration

  def change
    reversible do |dir|
      dir.up do


        create_table :test_things do |t|
          t.references :master, index: true, foreign_key: true
          t.integer :external_id, limit: 8
          t.references :user, index: true, foreign_key: true
          t.timestamps null: false      
        end

        create_table :test_thing_history do |t|
          t.references :test_thing, index: true, foreign_key: true
          t.references :master, index: true, foreign_key: true
          t.integer :external_id, limit: 8
          t.references :user, index: true, foreign_key: true
          t.timestamps null: false      
        end

        execute <<EOF

CREATE FUNCTION log_test_thing_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO test_thing_history
            (
                    test_thing_id,                    
                    external_id,
                    user_id,
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.external_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at 
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER test_thing_history_insert AFTER INSERT ON test_things FOR EACH ROW EXECUTE PROCEDURE log_test_thing_update();
CREATE TRIGGER test_thing_history_update AFTER UPDATE ON test_things FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_test_thing_update();

EOF

      end
      
      dir.down do
          drop_table :test_thing_history           
          drop_table :test_things 
          
          execute <<EOF

              DROP FUNCTION IF EXISTS log_test_thing_update() CASCADE;
EOF
      end
    end

  end
end
