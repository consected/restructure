class GenFilestoreReportFunctions < ActiveRecord::Migration
  def change

execute <<EOF

CREATE OR REPLACE FUNCTION filestore_report_perform_action(cid integer, altype varchar, alid integer, sf nfs_store_stored_files, af nfs_store_archived_files) RETURNS jsonb AS $$
	DECLARE
        jo jsonb;
        rt varchar;
        fn varchar;
        alt varchar;
    BEGIN

        rt := '"' || (CASE WHEN af.id IS NOT NULL THEN 'archived_file' ELSE 'stored_file' END) || '"';
        fn := '"' || (CASE WHEN af.id IS NOT NULL THEN af.file_name ELSE sf.file_name END) || '"';
		alt := '"' || altype || '"';
        jo := '{}';

        jo := jsonb_set(jo, '{perform_action}', '"/nfs_store/downloads/!container_id"');
        jo := jsonb_set(jo, '{container_id}', cid::varchar::jsonb);
        jo := jsonb_set(jo, '{download_id}', coalesce(af.id, sf.id)::varchar::jsonb);
        jo := jsonb_set(jo, '{activity_log_type}', alt::jsonb);
        jo := jsonb_set(jo, '{activity_log_id}', alid::varchar::jsonb);
        jo := jsonb_set(jo, '{retrieval_type}', rt::jsonb );
        jo := jsonb_set(jo, '{label}', fn::jsonb);

        return jo;

	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION filestore_report_select_fields(cid integer, altype varchar, alid integer, sfid integer, afid integer) RETURNS jsonb AS $$
	DECLARE
        jo jsonb;
        joid jsonb;
        rt varchar;
        alt varchar;
    BEGIN

    	rt := '"' || CASE WHEN afid IS NOT NULL THEN 'archived_file' ELSE 'stored_file' END || '"';
    	alt := '"' || altype || '"';

        joid := '{}'::jsonb;
        joid := jsonb_set(joid, '{id}', coalesce(afid, sfid)::varchar::jsonb);
        joid := jsonb_set(joid, '{retrieval_type}', rt::jsonb );
        joid := jsonb_set(joid, '{container_id}', cid::varchar::jsonb);
        joid := jsonb_set(joid, '{activity_log_type}', alt::jsonb);
        joid := jsonb_set(joid, '{activity_log_id}', alid::varchar::jsonb);


    	jo := '{}'::jsonb;
  		jo := jsonb_set(jo, '{field_name}', '"nfs_store_download[selected_items][]"');
    	jo := jsonb_set(jo, '{value}', joid);
    	return jo;

	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION filestore_report_file_path(sf nfs_store_stored_files, af nfs_store_archived_files) RETURNS VARCHAR AS $$
    BEGIN

      return CASE WHEN af.id IS NOT NULL THEN
        coalesce(sf.path, '') || '/' || sf.file_name || '/' || af.path
        ELSE sf.path
      END;

	END;
$$ LANGUAGE plpgsql;


EOF

  end
end
