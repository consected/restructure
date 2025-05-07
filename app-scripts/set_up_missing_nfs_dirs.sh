#!/bin/bash
# Set up NFS directories for app types in the list generated during initialization of the app.

cd "$(dirname $0)/.."

export FS_TEST_BASE
export MOUNTPOINT
export RAILS_ENV
export SUBDIR

if [ ! -f tmp/nfs_apps_list.txt ]; then
  echo "No file /tmp/nfs_apps_list.txt found. Exiting." >&2
  exit 0
fi

cat tmp/nfs_apps_list.txt | while read -r line; do
  APP_TYPE_ID=$(echo "$line" | cut -d' ' -f1)
  EXISTS=$(echo "$line" | cut -d' ' -f2)
  SUBDIR=$(echo "$line" | cut -d' ' -f3)

  [ "${EXISTS}" == 'true' ] && continue 
  
  SUBDIR=${SUBDIR} app-scripts/setup_filestore_app.sh "${APP_TYPE_ID}"
  if [ $? -ne 0 ]; then
    echo "Failed to set up app type ${APP_TYPE_ID}" >&2
  else
    RESTART_REQUIRED=true
  fi
done

rm -f tmp/nfs_apps_list.txt
if [ "${RESTART_REQUIRED}" ]; then
  echo "Restarting app server"
  NO_SLEEP=true app-scripts/restart_app_server.sh
fi

exit 0
