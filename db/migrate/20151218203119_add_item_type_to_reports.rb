class AddItemTypeToReports < ActiveRecord::Migration
  def change


    add_column :reports, :item_type, :string

    # some schemas may not have a report_history table
    # handle that explicitly
    if ActiveRecord::Base.connection.table_exists? 'report_history'
    

      add_column :report_history, :item_type, :string

          # history table seems to have been left behind. Bring it up to date  then remake the trigger
      add_column :report_history, :edit_model, :string
      add_column :report_history, :edit_field_names, :string
      add_column :report_history, :selection_fields, :string
    else
      create_table "report_history", force: :cascade do |t|
        t.string   "name"
        t.string   "description"
        t.string   "sql"
        t.string   "search_attrs"
        t.integer  "admin_id"
        t.boolean  "disabled"
        t.string   "report_type"
        t.boolean  "auto"
        t.boolean  "searchable"
        t.integer  "position"
        t.datetime "created_at",       null: false
        t.datetime "updated_at",       null: false
        t.integer  "report_id"
        t.string   "item_type"
        t.string   "edit_model"
        t.string   "edit_field_names"
        t.string   "selection_fields"
      end
    end

    reversible do |dir|
      dir.up do    
    execute <<EOF

DROP TRIGGER IF EXISTS report_history_insert ON reports;
DROP TRIGGER IF EXISTS report_history_update ON reports;
DROP FUNCTION IF EXISTS log_report_update();
CREATE FUNCTION log_report_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO report_history
            (
                    report_id,
                    name,                    
                    description,
                    sql,
                    search_attrs,
                    admin_id,
                    disabled,
                    report_type,
                    auto,
                    searchable,
                    position,
                    created_at,
                    updated_at,
                    edit_field_names,
                    selection_fields,
                    item_type
                )                 
            SELECT                 
                NEW.id,
                NEW.name,                
                NEW.description,
                NEW.sql,
                NEW.search_attrs,
                NEW.admin_id,                
                NEW.disabled,
                NEW.report_type,
                NEW.auto,
                NEW.searchable,
                NEW.position,                
                NEW.created_at,
                NEW.updated_at,
                NEW.edit_field_names,
                NEW.selection_fields,
                NEW.item_type
            ;
            RETURN NEW;
        END;
    $$;


    
CREATE TRIGGER report_history_insert AFTER INSERT ON reports FOR EACH ROW EXECUTE PROCEDURE log_report_update();
CREATE TRIGGER report_history_update AFTER UPDATE ON reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_report_update();


EOF
      end
      
      dir.down do
      
execute <<EOF

DROP TRIGGER IF EXISTS report_history_insert ON reports;
DROP TRIGGER IF EXISTS report_history_update ON reports;
DROP FUNCTION IF EXISTS log_report_update();
CREATE FUNCTION log_report_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO report_history
            (
                    report_id,
                    name,                    
                    description,
                    sql,
                    search_attrs,
                    admin_id,
                    disabled,
                    report_type,
                    auto,
                    searchable,
                    position,
                    created_at,
                    updated_at,
                    edit_field_names,
                    selection_fields
                )                 
            SELECT                 
                NEW.id,
                NEW.name,                
                NEW.description,
                NEW.sql,
                NEW.search_attrs,
                NEW.admin_id,                
                NEW.disabled,
                NEW.report_type,
                NEW.auto,
                NEW.searchable,
                NEW.position,                
                NEW.created_at,
                NEW.updated_at,
                NEW.edit_field_names,
                NEW.selection_fields
            ;
            RETURN NEW;
        END;
    $$;


    
CREATE TRIGGER report_history_insert AFTER INSERT ON reports FOR EACH ROW EXECUTE PROCEDURE log_report_update();
CREATE TRIGGER report_history_update AFTER UPDATE ON reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_report_update();


EOF
      end
    end    
  end
end
