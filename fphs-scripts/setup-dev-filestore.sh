#! /bin/bash
if [ "$(whoami)" != 'root' ]; then
  echo Must be sudo to run
  exit
fi
FS_ROOT=${HOME}/test-fphsfs
FS_DIR=main
MOUNT_ROOT=/mnt/fphsfs
WEBAPP_USER=${USER}
mkdir -p $FS_ROOT
getent group 599 || groupadd --gid 599 nfs_store_all_access
getent group 600 || groupadd --gid 600 nfs_store_group_0
getent group 601 || groupadd --gid 601 nfs_store_group_1
getent passwd 600 || useradd --user-group --uid 600 nfsuser
usermod -a --groups=599,600,601 $WEBAPP_USER
mkdir -p $FS_ROOT
mkdir -p $MOUNT_ROOT/gid600
mkdir -p $MOUNT_ROOT/gid601
mountpoint -q $MOUNT_ROOT/gid600 || bindfs --map=@600/@599 --create-for-group=600 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid600
mountpoint -q $MOUNT_ROOT/gid601 || bindfs --map=@601/@599 --create-for-group=601 --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNT_ROOT/gid601
