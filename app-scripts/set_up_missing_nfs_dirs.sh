#!/bin/bash
# Set up NFS directories for app types in the list generated during initialization of the app.

cd "$(dirname "$0")/.." || exit 1

export FS_TEST_BASE
export MOUNTPOINT
export RAILS_ENV
export SUBDIR

# Only a successful setup in this run may request a restart, never an inherited value.
RESTART_REQUIRED=
# Status from setup_filestore_app.sh when an app type needed no changes
UNCHANGED_EXIT_CODE=3

LIST=tmp/nfs_apps_list.txt
# The list is moved here while it is processed, so a newer list written by an app boot
# during this run is left in place for the next run rather than being archived unprocessed
WORKING_LIST=${LIST}.processing

# Allow only one run at a time, so overlapping cron runs can't take each other's working list
if ! exec 9> tmp/nfs_apps_list.lock; then
  echo "Failed to open the NFS app list lock file. Exiting." >&2
  exit 1
fi
if ! flock -n 9; then
  echo "Another NFS app list run is in progress. Exiting."
  exit 0
fi

# Recover a list claimed by an interrupted run, unless the app has written a newer one since
if [ -f "${WORKING_LIST}" ]; then
  if [ -f "${LIST}" ]; then
    rm -f "${WORKING_LIST}"
  elif ! mv "${WORKING_LIST}" "${LIST}"; then
    echo "Failed to recover the NFS app list from ${WORKING_LIST}. Exiting." >&2
    exit 1
  fi
fi

if [ ! -f "${LIST}" ]; then
  rp=$(realpath "${LIST}")
  echo "No file ${rp} found. Exiting." >&2
  exit 0
fi
export RAILS_ENV=${RAILS_ENV:='production'}

if [ "${RAILS_ENV}" == 'production' ]; then
  r='^([\\/a-zA-Z0-9\\-]+)'
  res=$(mount | grep 'gid600 type fuse')
  [[ ${res} =~ ${r} ]]
  export MOUNTPOINT=${BASH_REMATCH[1]}

  if [ -z "${MOUNTPOINT}" ]; then
    echo "MOUNTPOINT is not set. Exiting." >&2
    exit 1
  fi
fi

if ! mv "${LIST}" "${WORKING_LIST}"; then
  echo "Failed to claim the NFS app list; no restart was requested." >&2
  exit 1
fi

# Report the error and put the list back for the next run, without restarting
retain_list_and_exit() {
  echo "$1" >&2
  # A newer list written by an app boot during this run supersedes the one that failed
  if [ -e "${LIST}" ]; then
    rm -f "${WORKING_LIST}"
  elif ! mv -n "${WORKING_LIST}" "${LIST}"; then
    echo "Failed to restore the NFS app list; it will be recovered from ${WORKING_LIST} on the next run." >&2
  fi
  exit 1
}

# Group the redirected loop to catch input-open errors without a subshell;
# otherwise RESTART_REQUIRED set below would be lost once the loop exits.
if ! {
  while read -r line || [ -n "$line" ]; do
    APP_TYPE_ID=$(echo "$line" | cut -d' ' -f1)
    EXISTS=$(echo "$line" | cut -d' ' -f2)
    SUBDIR=$(echo "$line" | cut -d' ' -f3)
    # The containers path the app checks; may contain spaces and is absent from older lists
    APP_CONTAINERS_PATH=$(echo "$line" | cut -d' ' -f4-)

    [ "${EXISTS}" == 'true' ] && continue

    # Detach from the loop's stdin so an unexpected interactive prompt fails fast
    # instead of silently consuming the next line of the list. Close the lock so it is never inherited.
    SUBDIR="${SUBDIR}" UNCHANGED_EXIT_CODE=${UNCHANGED_EXIT_CODE} \
      app-scripts/setup_filestore_app.sh "${APP_TYPE_ID}" < /dev/null 9>&-
    SETUP_STATUS=$?
    if [ "${SETUP_STATUS}" -ne 0 ] && [ "${SETUP_STATUS}" -ne "${UNCHANGED_EXIT_CODE}" ]; then
      retain_list_and_exit "Failed to set up app type ${APP_TYPE_ID}; retaining the NFS app list for retry."
    fi

    if [ -n "${APP_CONTAINERS_PATH}" ] && [ ! -d "${APP_CONTAINERS_PATH}" ]; then
      retain_list_and_exit "App type ${APP_TYPE_ID} was set up, but the app's containers path ${APP_CONTAINERS_PATH} does not exist. Check MOUNTPOINT and SUBDIR; retaining the NFS app list and no restart was requested."
    fi

    # Restart only for real changes, so an app that still can't see an unchanged setup won't restart repeatedly.
    if [ "${SETUP_STATUS}" -eq 0 ]; then
      RESTART_REQUIRED=true
    fi
  done < "${WORKING_LIST}"
}; then
  retain_list_and_exit "Failed to read the NFS app list; no restart was requested."
fi

if ! mv -f "${WORKING_LIST}" "${LIST}.bak"; then
  retain_list_and_exit "Failed to archive the NFS app list; no restart was requested."
fi

if [ "${RESTART_REQUIRED}" = true ]; then
  echo "Restarting app server"
  NO_SLEEP=true app-scripts/restart_app_server.sh 9>&-
fi

exit 0
