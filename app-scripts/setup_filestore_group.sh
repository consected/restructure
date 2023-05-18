#!/bin/bash
# Set up a new NFS group for applying security to specific apps and containers
#
# Example on a production server: `app-scripts/setup_filestore_app.sh 2`
#
# NOTE: the server-build setup_restructure_eb.sh script that runs on startup of EB servers
# handles the creation of groups and setup of bindfs mounts when the server reboots. In general this is
# the preferred mechanism for setting up groups and mounts, since they will be recovered after restart

if -z $1; then
  echo "Enter the container security group number. For example, 2 maps to group ID 602 with name nfs_store_group_2"
  exit 1
fi

FS_ROOT=${FS_ROOT:=/efs-prod}
FS_DIR=${FS_DIR:=main}
MOUNTPOINT=${MOUNTPOINT:=/mnt/fphsfs}
BASE_NUM=$1
GRP_NUM=$((${BASE_NUM} + 600))
OWNER_GROUP="nfs_store_group_${BASE_NUM}"

echo "become sudo to setup group"
sudo echo "${BASE_NUM} > ${GRP_NUM} > ${OWNER_GROUP}"

getent group ${GRP_NUM} || groupadd --gid ${GRP_NUM} ${OWNER_GROUP}
mkdir -p $MOUNTPOINT/gid${GRP_NUM}
mountpoint -q $MOUNTPOINT/gid${GRP_NUM} || bindfs --map=@${GRP_NUM}/@599 --create-for-group=${GRP_NUM} --create-for-user=600 --chown-ignore --chmod-ignore --create-with-perms='u=rwD:g=rwD:o=' $FS_ROOT/$FS_DIR $MOUNTPOINT/gid${GRP_NUM}
