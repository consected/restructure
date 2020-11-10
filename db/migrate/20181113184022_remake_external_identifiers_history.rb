class RemakeExternalIdentifiersHistory < ActiveRecord::Migration
  def change

#
reversible do |dir|
  dir.up do

execute <<EOF

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create external_identifiers name label external_id_attribute external_id_view_formatter external_id_edit_pattern prevent_edit pregenerate_ids min_id max_id alphanumeric extra_fields

CREATE OR REPLACE FUNCTION log_external_identifier_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO external_identifier_history
            (
                name,
                label,
                external_id_attribute,
                external_id_view_formatter,
                external_id_edit_pattern,
                prevent_edit,
                pregenerate_ids,
                min_id,
                max_id,
                alphanumeric,
                extra_fields,
                admin_id,
                disabled,
                created_at,
                updated_at,
                external_identifier_id
                )
            SELECT
                NEW.name,
                NEW.label,
                NEW.external_id_attribute,
                NEW.external_id_view_formatter,
                NEW.external_id_edit_pattern,
                NEW.prevent_edit,
                NEW.pregenerate_ids,
                NEW.min_id,
                NEW.max_id,
                NEW.alphanumeric,
                NEW.extra_fields,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

ALTER TABLE external_identifier_history
    ADD COLUMN alphanumeric BOOLEAN;


EOF
end
dir.down do

execute <<EOF


ALTER TABLE external_identifier_history DROP COLUMN alphanumeric;

EOF

end
end



  end
end
