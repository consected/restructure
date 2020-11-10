class DbUserMapping < ActiveRecord::Migration
  
  def change
    reversible do |dir|
      dir.up do
execute <<EOF

  ALTER table trackers alter column user_id set default null;
  DROP FUNCTION IF EXISTS current_user_id();
  
  CREATE FUNCTION current_user_id() RETURNS integer
    LANGUAGE plpgsql
    AS $$
      DECLARE
        user_id integer;
      BEGIN
        user_id := (select id from users where email = current_user limit 1);

        return user_id;
      END;
    $$;


    ALTER table trackers alter column user_id set default current_user_id();
    
EOF

      end
      dir.down do
execute <<EOF            
          ALTER table trackers alter column user_id set default null;
          drop function current_user_id();
EOF
       
        end
      end    
  end
    
end
