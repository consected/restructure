# Migration version added
class HistoryUpdates < ActiveRecord::Migration[4.2]
  def up
    execute <<EOF



  ALTER TABLE report_history
    add column short_name character varying,
    add column options character varying
  ;


  CREATE or REPLACE FUNCTION log_report_update() RETURNS trigger
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
                    item_type,
                    short_name,
                    options
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
                NEW.item_type,
                NEW.short_name,
                NEW.options
            ;
            RETURN NEW;
        END;
    $$;


    ALTER table page_layout_history
    add column description varchar;

    CREATE or REPLACE FUNCTION log_page_layout_update() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
          BEGIN
              INSERT INTO page_layout_history
              (
                      page_layout_id,
                      app_type_id,
                      layout_name,
                      panel_name,
                      panel_label,
                      panel_position,
                      options,
                      disabled,
                      admin_id,
                      created_at,
                      updated_at,
                      description
                  )
              SELECT
                  NEW.id,
                  NEW.app_type_id,
                  NEW.layout_name,
                  NEW.panel_name,
                  NEW.panel_label,
                  NEW.panel_position,
                  NEW.options,
                  NEW.disabled,
                  NEW.admin_id,
                  NEW.created_at,
                  NEW.updated_at,
                  NEW.description
              ;
              RETURN NEW;
          END;
      $$;


      ALTER TABLE activity_log_history
        add column category character varying
      ;

      CREATE or REPLACE FUNCTION log_activity_log_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_history
                  (
                      name,
                      activity_log_id,
                      admin_id,
                      created_at,
                      updated_at,
                      item_type,
                      rec_type,
                      disabled,
                      action_when_attribute,
                      field_list,
                      blank_log_field_list,
                      blank_log_name,
                      extra_log_types,
                      hide_item_list_panel,
                      main_log_name,
                      process_name,
                      table_name,
                      category
                      )
                  SELECT
                      NEW.name,
                      NEW.id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.item_type,
                      NEW.rec_type,
                      NEW.disabled,
                      NEW.action_when_attribute,
                      NEW.field_list,
                      NEW.blank_log_field_list,
                      NEW.blank_log_name,
                      NEW.extra_log_types,
                      NEW.hide_item_list_panel,
                      NEW.main_log_name,
                      NEW.process_name,
                      NEW.table_name,
                      NEW.category
                  ;
                  RETURN NEW;
              END;
          $$;



      ALTER TABLE message_template_history
        add column category character varying
      ;

      CREATE or REPLACE FUNCTION log_message_template_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
                  BEGIN
                      INSERT INTO message_template_history
                      (
                          name,
                          template_type,
                          message_type,
                          template,
                          category,
                          admin_id,
                          disabled,
                          created_at,
                          updated_at,
                          message_template_id
                          )
                      SELECT
                          NEW.name,
                          NEW.template_type,
                          NEW.message_type,
                          NEW.template,
                          NEW.category,
                          NEW.admin_id,
                          NEW.disabled,
                          NEW.created_at,
                          NEW.updated_at,
                          NEW.id
                      ;
                      RETURN NEW;
                  END;
              $$;


EOF
  end
end
