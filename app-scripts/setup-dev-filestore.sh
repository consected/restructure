#! /bin/bash

if [ -z "$MOUNTPOINT" ]
then
  if [ "$USER" == 'phil' ]
  then
    MOUNTPOINT=/media/phil/Data
  else
    MOUNTPOINT=/home/$USER/dev-filestore
  fi
fi

FS_ROOT=${MOUNTPOINT}/test-fphsfs
FS_DIR=main
MOUNT_ROOT=/mnt/fphsfs
WEBAPP_USER=${USER}

mountpoint -q $MOUNT_ROOT/gid600
if [ $? == 0 ]
then
  # Already set up. No need to continue.

  echo "mountpoint OK"
  exit
fi

if [ "$(whoami)" == 'root' ]
then
  echo Do not run as sudo
  exit
else
  sudo  echo > /dev/null
fi



if [ "${RAILS_ENV}" != 'test' ]
then
  mountpoint -q "${MOUNTPOINT}"
  if [ $? == 1 ]
  then
    echo "${MOUNTPOINT} is not a real mount point. Check the file system is mounted correctly at this location"
    exit 1
  fi
fi


if [ "${RAILS_ENV}" != 'test' ]
then
sudo mkdir -p $FS_ROOT
sudo getent group 599 || sudo groupadd --gid 599 nfs_store_all_access
sudo getent group 600 || sudo groupadd --gid 600 nfs_store_group_0
sudo getent group 601 || sudo groupadd --gid 601 nfs_store_group_1
sudo getent passwd 600 || sudo useradd --user-group --uid 600 nfsuser
sudo usermod -a --groups=599,600,601 $WEBAPP_USER
sudo mkdir -p $FS_ROOT
sudo mkdir -p $MOUNT_ROOT/gid600
sudo mkdir -p $MOUNT_ROOT/gid601
fi
sudo mountpoint -q $MOUNT_ROOT/gid600 || sudo bindfs --map=@600/@599 --create-for-group=600 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid600
sudo mountpoint -q $MOUNT_ROOT/gid601 || sudo bindfs --map=@601/@599 --create-for-group=601 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid601

mountpoint -q $MOUNT_ROOT/gid600
if [ $? == 1 ]
then
  echo "Failed to setup mountpoint"
  exit
else
  echo "mountpoint OK"
  exit
fi
