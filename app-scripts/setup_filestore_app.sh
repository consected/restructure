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
#
# Set UNCHANGED_EXIT_CODE (1-255) to exit with that status instead of 0 when the directories,
# ownership and permissions were already correct and nothing was changed.

APP_TYPE_ID=$1
FS_TEST_BASE=${FS_TEST_BASE:=$HOME}

if [ -n "${UNCHANGED_EXIT_CODE}" ] &&
  { ! [[ "${UNCHANGED_EXIT_CODE}" =~ ^[1-9][0-9]{0,2}$ ]] || [ "${UNCHANGED_EXIT_CODE}" -gt 255 ]; }; then
  echo "UNCHANGED_EXIT_CODE must be an integer from 1 to 255" >&2
  exit 1
fi

if [ -z "$APP_TYPE_ID" ]; then
  echo "Call with argument <app_type_id>"
  if ! read -r -p 'Enter app type ID: ' APP_TYPE_ID || [ -z "$APP_TYPE_ID" ]; then
    echo "App type ID is required" >&2
    exit 1
  fi
fi

if [ -z "$MOUNTPOINT" ]; then
  if [ "$RAILS_ENV" == 'production' ]; then
    MOUNTPOINT=/efs1
  else

    if [ -d "/media/$USER/Data" ]; then
      MOUNTPOINT="/media/$USER/Data"
    else
      FS_TEST_BASE=${FS_TEST_BASE:=$HOME}
      MOUNTPOINT=${FS_TEST_BASE}/dev-filestore
    fi

  fi
  if [ ! -d "${MOUNTPOINT}" ]; then
    echo "MOUNTPOINT ${MOUNTPOINT} does not exist. Where is it?"
    read -r -p 'MOUNTPOINT directory: ' MOUNTPOINT
  fi
fi

if [ ! -d "${MOUNTPOINT}" ]; then
  echo "MOUNTPOINT ${MOUNTPOINT} does not exist"
  exit 1
fi

echo "Mountpoint is: $MOUNTPOINT"

# SUBDIR may legitimately be set to an empty string by a caller (e.g. production
# has no subdir layer), so only prompt when it was never provided at all.
if [ -z "${SUBDIR+x}" ]; then
  if [ -t 0 ]; then
    ls "${MOUNTPOINT}"
    if ! read -r -p 'Enter the selected directory: ' SUBDIR; then
      echo "Failed to read the filestore subdirectory" >&2
      exit 1
    fi
  else
    SUBDIR=.
  fi
fi

OWNER_GROUP=${OWNER_GROUP:='nfs_store_group_0'}

FS_ROOT="${MOUNTPOINT}/${SUBDIR}"
FS_DIR=

if [ -d "${FS_ROOT}/main" ]; then
  FS_DIR=main
fi
APPTYPE_DIR=app-type-${APP_TYPE_ID}

cd "${FS_ROOT}/${FS_DIR}" || exit 1

CHANGED=
if [ ! -d "$APPTYPE_DIR/containers" ]; then
  CHANGED=true
fi

if ! mkdir -p "$APPTYPE_DIR/containers"; then
  echo "Failed to create filestore directories for app type ${APP_TYPE_ID}" >&2
  exit 1
fi

if ! STAT=$(stat -c %a-%U:%G "$APPTYPE_DIR"); then
  echo "Failed to inspect filestore permissions for ${APPTYPE_DIR}" >&2
  exit 1
fi

if ! STATC=$(stat -c %a-%U:%G "$APPTYPE_DIR/containers"); then
  echo "Failed to inspect filestore permissions for ${APPTYPE_DIR}/containers" >&2
  exit 1
fi

if [ "${STAT}" != "770-nfsuser:nfs_store_all_access" ] || [ "${STATC}" != "770-nfsuser:${OWNER_GROUP}" ]; then
  echo "become sudo to setup file ownership and permissions"
  if ! {
    sudo echo "in: $APPTYPE_DIR/containers" &&
      sudo chmod 770 "$APPTYPE_DIR" &&
      sudo chmod 770 "$APPTYPE_DIR/containers" &&
      sudo chown nfsuser:nfs_store_all_access "$APPTYPE_DIR" &&
      sudo chown "nfsuser:${OWNER_GROUP}" "$APPTYPE_DIR/containers"
  }; then
    echo "Failed to configure filestore permissions for app type ${APP_TYPE_ID}" >&2
    exit 1
  fi
  CHANGED=true
fi

if [ -z "${CHANGED}" ]; then
  echo "App type ${APP_TYPE_ID} filestore is already set up; nothing changed"
  exit "${UNCHANGED_EXIT_CODE:-0}"
fi

exit 0
