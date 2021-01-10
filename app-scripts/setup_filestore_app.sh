#!/bin/bash
# Setup a container for a new app type in the mounted NFS
#./setup_app_type.sh

APP_TYPE_ID=$1

if [ -z "$APP_TYPE_ID" ]; then
  echo "Call with argument <app_type_id>"
  read -p 'Enter app type ID: ' APP_TYPE_ID
fi

if [ -z "$MOUNTPOINT" ]; then
  if [ "$RAILS_ENV" == 'production' ]; then
    MOUNTPOINT=/efs1
  elif [ "$USER" == 'phil' ]; then
    MOUNTPOINT=/media/phil/Data
  else
    MOUNTPOINT=/home/$USER/dev-filestore
  fi
fi

echo "Mountpoint is: $MOUNTPOINT"

if [ -z "${SUBDIR}" ]; then
  ls ${MOUNTPOINT}
  read -p 'Enter the selected directory: ' SUBDIR
fi


FS_ROOT=${MOUNTPOINT}/${SUBDIR}
FS_DIR=main
APPTYPE_DIR=app-type-${APP_TYPE_ID}

cd $FS_ROOT/$FS_DIR
mkdir -p $APPTYPE_DIR/containers

echo "become sudo to setup file ownership"
sudo echo ""

sudo chmod 770 $APPTYPE_DIR
sudo chmod 770 $APPTYPE_DIR/containers
sudo chown nfsuser:nfs_store_all_access $APPTYPE_DIR
sudo chown nfsuser:nfs_store_group_0 $APPTYPE_DIR/containers
