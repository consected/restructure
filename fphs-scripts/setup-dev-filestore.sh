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

# if [ $(mountpoint -q $MOUNT_ROOT/gid601) ] && [ $(mountpoint -q $MOUNT_ROOT/gid601) ]
# then
#   echo "Setup Dev Filestore"
# else
#   echo "Dev Filestore already set up"
#   exit
# fi

if [ "${RAILS_ENV}" != 'test' ]
then
  if [ "$(whoami)" != 'root' ]
  then
    echo Must be sudo to run
    exit
  fi

  if [ ! "$(mountpoint "${MOUNTPOINT}")" ]
  then
    echo "${MOUNTPOINT} is not a real mount point. Check the file system is mounted correctly at this location"
    exit 1
  fi
fi

FS_ROOT=${MOUNTPOINT}/test-fphsfs
FS_DIR=main
MOUNT_ROOT=/mnt/fphsfs
WEBAPP_USER=${USER}

if [ "${RAILS_ENV}" != 'test' ]
then
mkdir -p $FS_ROOT
getent group 599 || groupadd --gid 599 nfs_store_all_access
getent group 600 || groupadd --gid 600 nfs_store_group_0
getent group 601 || groupadd --gid 601 nfs_store_group_1
getent passwd 600 || useradd --user-group --uid 600 nfsuser
usermod -a --groups=599,600,601 $WEBAPP_USER
mkdir -p $FS_ROOT
mkdir -p $MOUNT_ROOT/gid600
mkdir -p $MOUNT_ROOT/gid601
fi
mountpoint -q $MOUNT_ROOT/gid600 || bindfs --map=@600/@599 --create-for-group=600 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid600
mountpoint -q $MOUNT_ROOT/gid601 || bindfs --map=@601/@599 --create-for-group=601 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid601

if [ "$(mountpoint -q $MOUNT_ROOT/gid600)" ]
then
  echo "Failed to setup mountpoint"
  exit
else
  echo "mountpoint OK"
  exit
fi
