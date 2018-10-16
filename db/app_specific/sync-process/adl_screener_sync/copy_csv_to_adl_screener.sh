psql << cat >>EOF
\copy adl_screener_data from ~/NetBeansProjects/fphs/zeus-with-filestore/db/app_specific/sync-process/adl_screener_sync/adl_screener_data.csv delimiter ',' CSV HEADER;
EOF
