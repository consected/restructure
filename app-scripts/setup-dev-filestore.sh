#! /bin/bash
# Set up the filestore OS groups and mounts that allow the apps to
# enforce different OS level security without switching OS user.
# This script is typically run after every reboot of the development machine.
# If `./setup-init-mounts.sh` has not been run previously (only required one time)
# then run it first.

FS_TEST_BASE=${FS_TEST_BASE:=/home/$USER}

if [ -z "$MOUNTPOINT" ]; then
  if [ -d /media/$USER/Data ]; then
    MOUNTPOINT=/media/$USER/Data
  else
    MOUNTPOINT=${FS_TEST_BASE}/dev-filestore
  fi
fi

FS_ROOT=${MOUNTPOINT}/test-fphsfs
FS_DIR=main
if [ -z "$MOUNT_ROOT" ]; then
  if [ -d /mnt/fphsfs ]; then
    MOUNT_ROOT=/mnt/fphsfs
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

is_mountpoint $MOUNT_ROOT/gid600
if [ $? == 0 ] && [ "$(getent passwd 600)" ]; then
  # Already set up. No need to continue.

  echo "mountpoint OK"
  exit
fi

if [ "$(whoami)" == 'root' ] && [ -z ${FS_FORCE_ROOT} ]; then
  echo Do not run as sudo
  exit
else
  sudo echo > /dev/null
fi

if [ "${RAILS_ENV}" != 'test' ]; then
  is_mountpoint "${MOUNTPOINT}"
  if [ $? == 1 ]; then
    echo "${MOUNTPOINT} is not a real mount point. Check the file system is mounted correctly at this location"
    exit 1
  fi
fi

if [ "${RAILS_ENV}" != 'test' ]; then
  sudo mkdir -p $FS_ROOT
  sudo getent group 599 || sudo groupadd --gid 599 nfs_store_all_access
  sudo getent group 600 || sudo groupadd --gid 600 nfs_store_group_0
  sudo getent group 601 || sudo groupadd --gid 601 nfs_store_group_1
  sudo getent passwd 600 || sudo useradd --user-group --uid 600 nfsuser
  sudo usermod -a --groups=599,600,601 $WEBAPP_USER
  sudo mkdir -p $FS_ROOT/main
  sudo mkdir -p $MOUNT_ROOT/gid600
  sudo mkdir -p $MOUNT_ROOT/gid601
fi
is_mountpoint $MOUNT_ROOT/gid600 || sudo bindfs --map=@600/@599 --create-for-group=600 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid600
is_mountpoint $MOUNT_ROOT/gid601 || sudo bindfs --map=@601/@599 --create-for-group=601 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid601

is_mountpoint $MOUNT_ROOT/gid600
if [ $? == 1 ]; then
  ls -als $MOUNT_ROOT
  echo "Failed to setup mountpoint"
  exit 1
else
  echo "mountpoint OK"
  exit
fi
