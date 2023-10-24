#!/bin/bash
# Setup a container for a new app type in the mounted NFS.
# This sets up the structure expected by the apps filestore
# and sets the initial OS group with access to the container as `nfs_store_group_0`.
# This group maps to the app role `nfs_store group 600`
#
# The environment variables RAILS_ENV=production should be set if running on a production server
# otherwise the script assumes this is a dev / test machine.
#
# The admin panel App Types list show the specific script to be run for each app type.
# This only needs to be run one time, from a command line on a machine where the
# NFS filesystem is mounted at the location /efs1 - unless the MOUNTPOINT environment
# variable is set to point to another location.
#
# Example on a dev server: `app-scripts/setup_filestore_app.sh 1`
# Example on a production server: `RAILS_ENV=production app-scripts/setup_filestore_app.sh 1`

APP_TYPE_ID=$1
FS_TEST_BASE=${FS_TEST_BASE:=$HOME}

if [ -z "$APP_TYPE_ID" ]; then
  echo "Call with argument <app_type_id>"
  read -r -p 'Enter app type ID: ' APP_TYPE_ID
fi

if [ -z "$MOUNTPOINT" ]; then
  if [ "$RAILS_ENV" == 'production' ]; then
    MOUNTPOINT=/efs1
  else

    if [ -d /media/$USER/Data ]; then
      MOUNTPOINT=/media/$USER/Data
    else
      FS_TEST_BASE=${FS_TEST_BASE:=$HOME}
      MOUNTPOINT=${FS_TEST_BASE}/dev-filestore
    fi

  fi
  if [ ! -d ${MOUNTPOINT} ]; then
    echo "MOUNTPOINT ${MOUNTPOINT} does not exist. Where is it?"
    read -r -p 'MOUNTPOINT directory: ' MOUNTPOINT
  fi
fi

if [ ! -d "${MOUNTPOINT}" ]; then
  echo "MOUNTPOINT ${MOUNTPOINT} does not exist"
  exit 1
fi

echo "Mountpoint is: $MOUNTPOINT"

if [ -z "${SUBDIR}" ]; then
  ls "${MOUNTPOINT}"
  read -r -p 'Enter the selected directory: ' SUBDIR
fi

OWNER_GROUP=${OWNER_GROUP:='nfs_store_group_0'}

FS_ROOT=${MOUNTPOINT}/${SUBDIR}

if [ -d ${FS_ROOT}/main ]; then
  FS_DIR=main
fi
APPTYPE_DIR=app-type-${APP_TYPE_ID}

cd "$FS_ROOT"/$FS_DIR || exit 1

mkdir -p "$APPTYPE_DIR"/containers

echo "become sudo to setup file ownership"
sudo echo "in: $APPTYPE_DIR/containers"

sudo chmod 770 "$APPTYPE_DIR"
sudo chmod 770 "$APPTYPE_DIR"/containers
sudo chown nfsuser:nfs_store_all_access "$APPTYPE_DIR"
sudo chown nfsuser:${OWNER_GROUP} "$APPTYPE_DIR"/containers
