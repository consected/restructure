#! /bin/bash
# Set up the filestore OS groups and mounts that allow the apps to
# enforce different OS level security without switching OS user.
# This script is typically run after every reboot of the development machine.
# If `./setup-init-mounts.sh` has not been run previously (only required one time)
# then run it first.

# The following environment variables can be set:
# - FS_TEST_BASE: the base directory to use for the test filestore. Defaults to $HOME.
# - TEST_ENV_SET: if set, this is used as a subdirectory of FS_TEST_BASE to allow multiple different test filestore setups to be used on the same machine.
# - MOUNTPOINT: the directory where the underlying NFS filesystem is mounted. If not set, it defaults to /media/$USER/Data or /media/$USER/Data/${TEST_ENV_SET} if TEST_ENV_SET is set, or ${FS_TEST_BASE}/dev-filestore if the media directory does not exist.
# - MOUNT_ROOT: the directory where the bind mounts are created. If not set, it defaults to /mnt/fphsfs or /mnt/fphsfs/${TEST_ENV_SET
# - FORCE_MOUNT: if set to "true", the script will force remount the bind mounts even if they are already set up. This is useful if the mounts are in a bad state and need to be reset.

FS_TEST_BASE=${FS_TEST_BASE:=$HOME}
if [ "${TEST_ENV_SET}" ]; then
  FS_TEST_BASE=${FS_TEST_BASE}/${TEST_ENV_SET}
fi

if [ -z "$MOUNTPOINT" ]; then
  MEDIA_DIR="/media/$USER/Data"
  if [ "${TEST_ENV_SET}" ]; then
    MEDIA_DIR="/media/$USER/Data/${TEST_ENV_SET}"
  fi

  if [ -d "$MEDIA_DIR" ]; then
    MOUNTPOINT="$MEDIA_DIR"
  else
    MOUNTPOINT=${FS_TEST_BASE}/dev-filestore
  fi
fi

FS_ROOT=${MOUNTPOINT}/test-fphsfs
FS_DIR=main
if [ -z "$MOUNT_ROOT" ]; then
  if [ -d /mnt/fphsfs ]; then
    MOUNT_ROOT=/mnt/fphsfs
    if [ "${TEST_ENV_SET}" ]; then
      MOUNT_ROOT=/mnt/fphsfs/${TEST_ENV_SET}
    fi
  else
    MOUNT_ROOT=${FS_TEST_BASE}/dev-bind-fs
  fi
fi

WEBAPP_USER=${WEBAPP_USER:=$USER}

function is_mountpoint() {
  if [ "$(which mountpoint)" ]; then
    mountpoint -q $1
  elif [ "$(which diskutil)" ]; then
    diskutil info "$1" > /dev/null
  else
    echo "Either mountpoint (Linux) or diskutil (macOS) must be installed"
    exit 7
  fi
}

if [ "$FORCE_MOUNT" != "true" ]; then
  is_mountpoint "$MOUNT_ROOT/gid600"
  if [ $? == 0 ] && [ "$(getent passwd 600)" ]; then
    # Already set up. No need to continue.

    echo "mountpoint OK"
    exit
  fi
fi

if [ "$(whoami)" == 'root' ] && [ -z "${FS_FORCE_ROOT}" ]; then
  echo Do not run as sudo
  exit
else
  sudo echo "Set up dev filestore" > /dev/null
fi

if [ "${RAILS_ENV}" != 'test' ]; then
  mountpoint -q "${MOUNTPOINT}"
  if [ $? != 0 ]; then
    echo "${MOUNTPOINT} is not a real mount point. Check the file system is mounted correctly at this location"
    exit 1
  fi
fi

if [ "${RAILS_ENV}" != 'test' ]; then
  mkdir -p "$FS_ROOT"
  sudo getent group 599 || sudo groupadd --gid 599 nfs_store_all_access
  sudo getent group 600 || sudo groupadd --gid 600 nfs_store_group_0
  sudo getent group 601 || sudo groupadd --gid 601 nfs_store_group_1
  sudo getent passwd 600 || sudo useradd --user-group --uid 600 nfsuser
  sudo usermod -a --groups=599,600,601 "$WEBAPP_USER"
  mkdir -p "$FS_ROOT/$FS_DIR"
  mkdir -p "$MOUNT_ROOT" || sudo mkdir -p "$MOUNT_ROOT" && sudo chmod 777 "$MOUNT_ROOT"
  mkdir -p "$MOUNT_ROOT/gid600"
  mkdir -p "$MOUNT_ROOT/gid601"
fi

WEBAPP_USER_ID=$(id -u "$WEBAPP_USER")

if [ "$FORCE_MOUNT" == "true" ]; then
  sudo umount "$MOUNT_ROOT/gid600"
  sudo umount "$MOUNT_ROOT/gid601"
fi

is_mountpoint "$MOUNT_ROOT/gid600" || sudo bindfs --map=@600/@599 --create-for-group=600 --create-for-user="${WEBAPP_USER_ID}" --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' "$FS_ROOT/$FS_DIR" "$MOUNT_ROOT/gid600"
is_mountpoint "$MOUNT_ROOT/gid601" || sudo bindfs --map=@601/@599 --create-for-group=601 --create-for-user="${WEBAPP_USER_ID}" --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' "$FS_ROOT/$FS_DIR" "$MOUNT_ROOT/gid601"

is_mountpoint "$MOUNT_ROOT/gid600"
if [ $? == 0 ]; then
  echo "mountpoint OK"
  exit
else
  ls -als "$MOUNT_ROOT"
  echo "Failed to setup mountpoint"
  exit 1
fi